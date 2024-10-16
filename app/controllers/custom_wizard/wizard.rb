# frozen_string_literal: true
class CustomWizard::WizardController < ::CustomWizard::WizardClientController
  def show
    if wizard.present?
      render json: CustomWizard::WizardSerializer.new(wizard, scope: guardian, root: false).as_json,
             status: 200
    else
      render json: { error: I18n.t("wizard.none") }
    end
  end

  def skip
    params.require(:wizard_id)

    if wizard.required && !wizard.completed? && wizard.permitted?
      return render json: { error: I18n.t("wizard.no_skip") }
    end

    result = { success: "OK" }

    if current_user && wizard.can_access?
      if redirect_to = wizard.current_submission&.redirect_to
        result.merge!(redirect_to: redirect_to)
      end

      wizard.cleanup_on_skip!
    end

    render json: result
  end

  protected

  def wizard
    @wizard ||=
      begin
        return nil if @builder.blank?
        @builder.build({ reset: params[:reset] }, params)
      end
  end
end
