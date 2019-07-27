import CustomWizard from '../models/custom-wizard';
export default Discourse.Route.extend({

  model(){
  return CustomWizard.all()
  },
  isEmberized: true
  // isEmberized(){
  //   return true;
  // }
})
