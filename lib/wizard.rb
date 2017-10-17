require_dependency 'wizard/step'
require_dependency 'wizard/field'
require_dependency 'wizard/step_updater'
require_dependency 'wizard/builder'

class CustomWizard::Wizard

  attr_reader :steps, :user
  attr_accessor :id, :name, :background, :save_submissions, :multiple_submissions

  def initialize(user, attrs = {})
    @steps = []
    @user = user
    @first_step = nil
    @id = attrs[:id] if attrs[:id]
    @name = attrs[:name] if attrs[:name]
    @save_submissions = attrs[:save_submissions] if attrs[:save_submissions]
    @multiple_submissions = attrs[:multiple_submissions] if attrs[:multiple_submissions]
    @background = attrs[:background] if attrs[:background]
  end

  def create_step(step_name)
    ::Wizard::Step.new(step_name)
  end

  def append_step(step)
    step = create_step(step) if step.is_a?(String)

    yield step if block_given?

    last_step = @steps.last

    @steps << step

    # If it's the first step
    if @steps.size == 1
      @first_step = step
      step.index = 0
    elsif last_step.present?
      last_step.next = step
      step.previous = last_step
      step.index = last_step.index + 1
    end
  end

  def start
    completed = ::UserHistory.where(
      acting_user_id: @user.id,
      action: ::UserHistory.actions[:custom_wizard_step]
    ).where(context: @steps.map(&:id))
      .uniq.pluck(:context)

    @steps.each do |s|
      return s unless completed.include?(s.id)
    end

    @first_step
  end

  def completed_steps?(steps)
    steps = [steps].flatten.uniq

    completed = ::UserHistory.where(
      acting_user_id: @user.id,
      action: ::UserHistory.actions[:custom_wizard_step]
    ).where(context: steps)
      .distinct.order(:context).pluck(:context)

    steps.sort == completed
  end

  def create_updater(step_id, fields)
    step = @steps.find { |s| s.id == step_id.dasherize }
    wizard = self
    CustomWizard::StepUpdater.new(@user, wizard, step, fields)
  end

  def completed?
    completed_steps?(@steps.map(&:id))
  end
end
