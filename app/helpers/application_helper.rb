# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def  app_number_to_currency(value)
     number_to_currency(value, :precision => 0)
  end
end
