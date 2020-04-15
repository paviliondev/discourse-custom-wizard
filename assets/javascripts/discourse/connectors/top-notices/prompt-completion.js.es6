export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.custom_wizard_enabled && 
      ctx.site.complete_custom_wizard;
  }
}