module ApplicationHelper
  def menu_category_dom_id(category)
    "menu-#{category.to_s.parameterize}"
  end

  def current_user_can?(tab)
    current_user&.can_access_tab?(tab)
  end

  def can_view_paid_bills?
    current_user&.can_view_paid_bills?
  end
end
