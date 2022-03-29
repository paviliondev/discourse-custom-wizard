const subscriptionTypes = ["standard", "business"];

function subscriptionTypeSufficient(subscriptionType, requiredType) {
  if (requiredType && !subscriptionType) {
    return false;
  }
  if (requiredType === "none" || requiredType === null) {
    return true;
  }
  if (
    requiredType === "standard" &&
    subscriptionTypes.includes(subscriptionType)
  ) {
    return true;
  }
  if (requiredType === "business" && subscriptionType === "business") {
    return true;
  }
  return false;
}

export { subscriptionTypeSufficient, subscriptionTypes };
