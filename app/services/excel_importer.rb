class ExcelImporter
  COLUMN_MAP = {
    "item name" => :item_name,
    "item_name" => :item_name,
    "name" => :item_name,
    "item" => :item_name,
    "category" => :category,
    "quantity" => :quantity,
    "qty" => :quantity,
    "opening quantity" => :opening_quantity,
    "opening_quantity" => :opening_quantity,
    "unit" => :unit,
    "price" => :price,
    "rate" => :price,
    "supplier" => :supplier,
    "vendor" => :supplier,
    "notes" => :notes,
    "remarks" => :notes
  }.freeze

  def self.parse(file)
    spreadsheet = open_spreadsheet(file)
    header_row = spreadsheet.row(1)
    headers = header_row.map { |h| normalize_header(h) }

    (2..spreadsheet.last_row).filter_map do |row_num|
      row = spreadsheet.row(row_num)
      next if row.compact.blank?

      parsed = {}
      headers.each_with_index do |header, index|
        key = COLUMN_MAP[header]
        next unless key

        parsed[key] = cast_value(key, row[index])
      end

      next if parsed[:item_name].blank?

      parsed
    end
  end

  def self.open_spreadsheet(file)
    path = file.respond_to?(:path) ? file.path : file
    ext = File.extname(path).downcase

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

    case key
    when :quantity, :opening_quantity, :price
      value.to_s.strip.empty? ? 0 : value.to_d
    else
      value.to_s.strip
    end
  end
end
