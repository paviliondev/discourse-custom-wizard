import ValueList from 'admin/components/value-list';

export default ValueList.extend({
  _saveValues() {
    if (this.inputType === "array") {
      this.onChange(this.collection);
      return;
    }

    this.onChange(this.collection.join(this.inputDelimiter || "\n"));
  }
})