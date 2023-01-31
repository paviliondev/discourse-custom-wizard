# frozen_string_literal: true

describe CustomWizard::CustomField do
  let(:custom_field_json) { get_wizard_fixture("custom_field/custom_fields") }
  let(:custom_field_subscription_json) { get_wizard_fixture("custom_field/subscription_custom_fields") }

  before do
    CustomWizard::CustomField.invalidate_cache
  end

  it "saves custom field records" do
    custom_field_json['custom_fields'].each do |field_json|
      custom_field = CustomWizard::CustomField.new(nil, field_json)
      expect(custom_field.save).to eq(true)
      expect(
        PluginStoreRow.where("
          plugin_name = '#{CustomWizard::CustomField::NAMESPACE}' AND
          key = '#{custom_field.name}' AND
          value::jsonb = '#{field_json.except('name').to_json}'::jsonb
        ",).exists?
      ).to eq(true)
    end
  end

  it "updates existing custom field records" do
    custom_field_json['custom_fields'].each do |field_json|
      CustomWizard::CustomField.new(nil, field_json).save
    end

    updated_field_json = custom_field_json['custom_fields'][0]
    updated_field_json['serializers'] = ["topic_view"]
    existing_field = CustomWizard::CustomField.find_by_name(updated_field_json["name"])
    updated_field = CustomWizard::CustomField.new(existing_field.id, updated_field_json)

    expect(updated_field.save).to eq(true)
    expect(
      PluginStoreRow.where("
        plugin_name = '#{CustomWizard::CustomField::NAMESPACE}' AND
        key = '#{updated_field.name}' AND
        value::jsonb = '#{updated_field_json.except('name').to_json}'::jsonb
      ",).exists?
    ).to eq(true)
  end

  context "validation" do
    it "does not save without required attributes" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['klass'] = nil

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)
      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.required_attribute", attr: "klass")
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does save without optional attributes" do
      field_json = custom_field_json['custom_fields'].first
      field_json['serializers'] = nil

      custom_field = CustomWizard::CustomField.new(nil, field_json)
      expect(custom_field.save).to eq(true)
      expect(custom_field.valid?).to eq(true)
      expect(
        PluginStoreRow.where("
          plugin_name = '#{CustomWizard::CustomField::NAMESPACE}' AND
          key = '#{custom_field.name}' AND
          value::jsonb = '#{field_json.except('name').to_json}'::jsonb
        ",).exists?
      ).to eq(true)
    end

    it "does not save with an unsupported class" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['klass'] = 'user'

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.unsupported_class", class: "user")
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does not save with an unsupported serializer" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['klass'] = 'post'
      invalid_field_json['serializers'] = ['post', 'post_revision']

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.unsupported_serializers",
          class: "post",
          serializers: "post_revision"
        )
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does not save with an unsupported type" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['type'] = 'bigint'

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.unsupported_type", type: "bigint")
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does not save with a short field name" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['name'] = 'cf'

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.name_too_short", name: "cf")
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does not save with an existing name if new" do
      custom_field_json['custom_fields'].each do |field_json|
        CustomWizard::CustomField.new(nil, field_json).save
      end

      first_field_json = custom_field_json['custom_fields'][0]
      custom_field = CustomWizard::CustomField.new(nil, first_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.name_already_taken", name: "topic_field_1")
      )
    end

    it "does not save with an invalid name" do
      invalid_field_json = custom_field_json['custom_fields'].first
      invalid_field_json['name'] = ["invalid_name"]

      custom_field = CustomWizard::CustomField.new(nil, invalid_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.name_invalid", name: ["invalid_name"])
      )
      expect(
        PluginStoreRow.where(
          plugin_name: CustomWizard::CustomField::NAMESPACE,
          key: custom_field.name
        ).exists?
      ).to eq(false)
    end

    it "does not save subscription field types without a subscription" do
      subscription_field_json = custom_field_subscription_json['custom_fields'].first
      custom_field = CustomWizard::CustomField.new(nil, subscription_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.subscription_type", type: "json")
      )
    end

    it "does not save subscription field classes without a subscription" do
      subscription_field_json = custom_field_subscription_json['custom_fields'].second
      custom_field = CustomWizard::CustomField.new(nil, subscription_field_json)

      expect(custom_field.save).to eq(false)
      expect(custom_field.valid?).to eq(false)
      expect(custom_field.errors.full_messages.first).to eq(
        I18n.t("wizard.custom_field.error.subscription_type", type: "category")
      )
    end

    context "with a subscription" do
      before do
        enable_subscription("business")
      end

      it "saves subscription field types" do
        subscription_field_json = custom_field_subscription_json['custom_fields'].first
        custom_field = CustomWizard::CustomField.new(nil, subscription_field_json)

        expect(custom_field.save).to eq(true)
        expect(custom_field.valid?).to eq(true)
      end

      it "saves subscription field classes" do
        subscription_field_json = custom_field_subscription_json['custom_fields'].second
        custom_field = CustomWizard::CustomField.new(nil, subscription_field_json)

        expect(custom_field.save).to eq(true)
        expect(custom_field.valid?).to eq(true)
      end
    end
  end

  context "lists" do
    before do
      custom_field_json['custom_fields'].each do |field_json|
        CustomWizard::CustomField.new(nil, field_json).save
      end
    end

    it "saved custom field records" do
      expect(CustomWizard::CustomField.list.length).to eq(2)
    end

    it "saved custom field records by attribute value" do
      expect(CustomWizard::CustomField.list_by(:klass, 'topic').length).to eq(1)
    end

    it "saved custom field records by optional values" do
      field_json = custom_field_json['custom_fields'].first
      field_json['serializers'] = nil

      custom_field = CustomWizard::CustomField.new(nil, field_json)
      expect(CustomWizard::CustomField.list_by(:serializers, ['post']).length).to eq(0)
    end

    it "lists custom field records added by other plugins " do
      expect(CustomWizard::CustomField.external_list.length).to be > 2
    end

    it "lists all custom field records" do
      expect(CustomWizard::CustomField.full_list.length).to be > 2
    end
  end

  it "is enabled if there are custom fields" do
    custom_field_json['custom_fields'].each do |field_json|
      CustomWizard::CustomField.new(nil, field_json).save
    end
    expect(CustomWizard::CustomField.enabled?).to eq(true)
  end

  it "is not enabled if there are no custom fields" do
    expect(CustomWizard::CustomField.enabled?).to eq(false)
  end
end
