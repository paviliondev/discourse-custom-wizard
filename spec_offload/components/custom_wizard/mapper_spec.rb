describe CustomWizard::Mapper do
  fab!(:user) { Fabricate(:user, name: 'Angus', username: 'angus', email: "angus@email.com") }
  
  it 'interpolates user data' do
    expect(
      CustomWizard::Mapper.fill_placeholders(
        "My name is u{name}",
        user,
        {}
      )
    ).to eq('My name is Angus')
  end
end