import IndexRoute from 'wizard/routes/index';

export default IndexRoute.extend({
  beforeModel() {
    const appModel = this.modelFor('application');
    this.replaceWith('custom.step', appModel.start);
  }
});
