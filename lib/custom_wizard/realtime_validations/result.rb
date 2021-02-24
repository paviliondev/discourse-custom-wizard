class CustomWizard::RealtimeValidation::Result
  attr_accessor :type,
                :items,
                :serializer_opts

  def initialize(type)
    @type = type
    @items = []
    @serializer_opts = {}
  end
end
