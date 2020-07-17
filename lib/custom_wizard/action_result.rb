class CustomWizard::ActionResult
  attr_accessor :success, :handler, :output

  def initialize
    @success = false
  end

  def success?
    @success
  end

  def failed?
    !success
  end
end
