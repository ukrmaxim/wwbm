module ApplicationHelper
  def bootstrap_class_for(flash_type)
    {
      success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-success'
    }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end

  def bootstrap_flash(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show", role: "alert") do
        concat content_tag(:button, '', class: "btn-close", data: { bs_dismiss: 'alert' })
        concat message
      end)
    end
    nil
  end

  def fa_icon(icon_class)
    content_tag 'span', '', class: "fas fa-#{icon_class}"
  end
end
