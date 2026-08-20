class ExcelImporter
  QUANTITY_COLUMN_MAP = {
    "item name" => :item_name,
    "item_name" => :item_name,
    "name" => :item_name,
    "item" => :item_name,
    "quantity" => :quantity,
    "qty" => :quantity,
    "opening quantity" => :opening_quantity,
    "opening_quantity" => :opening_quantity,
    "unit" => :unit
  }.freeze

  GROCERY_COLUMN_MAP = {
    "sl no" => :serial_no,
    "sl no." => :serial_no,
    "s.no" => :serial_no,
    "s.no." => :serial_no,
    "serial no" => :serial_no,
    "serial no." => :serial_no,
    "item name" => :item_name,
    "item" => :item_name,
    "name" => :item_name,
    "old stock" => :old_stock,
    "new stock added" => :new_stock_added,
    "new stock" => :new_stock_added,
    "qty" => :unit,
    "unit" => :unit,
    "total updated stock" => :quantity,
    "total stock" => :quantity,
    "quantity" => :quantity
  }.freeze

  def self.parse(file)
    parse_with_map(file, QUANTITY_COLUMN_MAP)
  end

  def self.parse_grocery(file)
    parse_with_map(file, GROCERY_COLUMN_MAP, grocery: true)
  end

  def self.parse_with_map(file, column_map, grocery: false)
    spreadsheet = open_spreadsheet(file)
    header_row_index = find_header_row(spreadsheet, column_map)
    raise ArgumentError, "Could not find header row. Expected columns like Item Name, Old Stock, New Stock Added, Qty, Total Updated Stock." unless header_row_index

    headers = spreadsheet.row(header_row_index).map { |h| map_header(h, column_map, grocery: grocery) }

    ((header_row_index + 1)..spreadsheet.last_row).filter_map do |row_num|
      row = spreadsheet.row(row_num)
      next if row.compact.blank?

      parsed = {}
      headers.each_with_index do |key, index|
        next unless key

        parsed[key] = cast_value(key, row[index])
      end

      next if parsed[:item_name].blank?
      next if grocery && blank_stock_row?(parsed)

      if grocery
        parsed[:old_stock] ||= 0
        parsed[:new_stock_added] ||= 0
        parsed[:quantity] = parsed[:quantity].presence || (parsed[:old_stock].to_d + parsed[:new_stock_added].to_d)
      end

      parsed
    end
  end

  def self.find_header_row(spreadsheet, column_map)
    max_scan = [ spreadsheet.last_row, 15 ].min
    (1..max_scan).find do |row_num|
      headers = spreadsheet.row(row_num).map { |h| normalize_header(h) }
      mapped = headers.filter_map { |h| resolve_header_key(h, column_map) }
      mapped.include?(:item_name) && mapped.size >= 2
    end
  end

  def self.map_header(value, column_map, grocery: false)
    resolve_header_key(normalize_header(value), column_map, grocery: grocery)
  end

  def self.resolve_header_key(normalized, column_map, grocery: false)
    return column_map[normalized] if column_map[normalized]

    return :old_stock if normalized.start_with?("old stock")
    return :new_stock_added if normalized.start_with?("new stock")
    return :quantity if normalized.start_with?("total updated") || normalized.start_with?("total stock")
    return :serial_no if normalized.match?(/\A(sl\.?\s*no|s\.?\s*no|serial)/)
    return :unit if grocery && normalized == "qty"

    nil
  end

  def self.blank_stock_row?(parsed)
    [ parsed[:old_stock], parsed[:new_stock_added], parsed[:quantity], parsed[:unit] ].all? do |value|
      value.blank? || value.to_s.strip == "-" || value.to_s.strip == "—"
    end
  end

  def self.open_spreadsheet(file)
    path = file.respond_to?(:tempfile) ? file.tempfile.path : (file.respond_to?(:path) ? file.path : file)
    filename = file.respond_to?(:original_filename) ? file.original_filename : path.to_s
    ext = File.extname(filename).downcase
    ext = File.extname(path).downcase if ext.blank?

    case ext
    when ".xlsx"
      Roo::Excelx.new(path)
    when ".xls"
      Roo::Excel.new(path)
    when ".csv"
      Roo::CSV.new(path)
    else
      raise ArgumentError, "Unsupported file format. Please upload .xlsx, .xls, or .csv"
    end
  end

  def self.normalize_header(value)
    value.to_s.strip.downcase.gsub(/\s+/, " ")
  end

  def self.cast_value(key, value)
    return nil if value.nil?

    text = value.to_s.strip
    return nil if text.blank? || text == "-" || text == "—"

    case key
    when :quantity, :opening_quantity, :old_stock, :new_stock_added, :price
      # Keep leading number from values like "22.5 Pcs (22 ½)"
      numeric = text[/\d+(?:\.\d+)?/]
      numeric.present? ? numeric.to_d : 0
    when :serial_no
      text.to_i
    else
      text
    end
  end
end
