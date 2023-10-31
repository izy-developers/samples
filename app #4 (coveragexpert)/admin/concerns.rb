# frozen_string_literal: true

ActiveAdmin.register Concern do
  menu label: 'Concerns', parent: 'DB entities', priority: 3

  permit_params :name

  index do
    selectable_column
    id_column
    column :name

    actions
  end

  filter :name

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
    end
  end
end
