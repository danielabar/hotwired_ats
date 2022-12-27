# frozen_string_literal: true

class DraggableReflex < ApplicationReflex
  def update_record(resource, field, value)
    id = element.dataset.id
    resource = resource.constantize.find(id)
    resource.update("#{field}": value)

    morph :nothing
  end
end
