describe CustomWizard::Mapper do
  
it 'interpolates user data' do
  user.name = "Angus"
  user.save!
  
  expect(
    CustomWizard::Builder.fill_placeholders(
      "My name is u{name}",
      user,
      {}
    )
  ).to eq('My name is Angus')
end