module ExtraLocalesControllerCustomWizard
  def show
    if request.referer && URI(request.referer).path.include?('/w/')
      bundle = params[:bundle]
        
      if params[:v]&.size == 32
        hash = ::ExtraLocalesController.bundle_js_hash(bundle)
        immutable_for(1.year) if hash == params[:v]
      end

      render plain: ::ExtraLocalesController.bundle_js(bundle), content_type: "application/javascript"
    else
      super
    end
  end
end