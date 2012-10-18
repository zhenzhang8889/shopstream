module ApplicationHelper
  def flash_class(type)
    case type
    when :notice then nil
    when :error then 'alert'
    when :alert then 'alert'
    else type
    end
  end
end
