describe CustomWizard::Action do
  let(:create_topic_action) {{"id":"create_topic","type":"create_topic","title":"text","post":"textarea"}}
  let(:send_message_action) {{"id":"send_message","type":"send_message","title":"text","post":"textarea","username":"angus"}}
  let(:route_to_action) {{"id":"route_to","type":"route_to","url":"https://google.com"}}
  let(:open_composer_action) {{"id":"open_composer","type":"open_composer","title":"text","post":"textarea"}}
  let(:add_to_group_action) {{"id":"add_to_group","type":"add_to_group","group_id":"dropdown_groups"}}
  
  it 'creates a topic' do
    template['steps'][0]['fields'] = [text_field, textarea_field]
    template['steps'][0]["actions"] = [create_topic_action]
    updater = run_update(template, nil,
      text: "Topic Title",
      textarea: "topic body"
    )
    topic = Topic.where(title: "Topic Title")
    
    expect(topic.exists?).to eq(true)
    expect(Post.where(
      topic_id: topic.pluck(:id),
      raw: "topic body"
    ).exists?).to eq(true)
  end
  
  it 'sends a message' do
    fields = [text_field, textarea_field]
    
    if extra_field
      fields.push(extra_field)
    end
        
    template['steps'][0]['fields'] = fields
    template['steps'][0]["actions"] = [send_message_action.merge(extra_action_opts)]
    
    run_update(template, nil,
      text: "Message Title",
      textarea: "message body"
    )
    
    topic = Topic.where(
      archetype: Archetype.private_message,
      title: "Message Title"
    )
    
    expect(topic.exists?).to eq(true)
    expect(
      topic.first.topic_allowed_users.first.user.username
    ).to eq('angus')
    expect(Post.where(
      topic_id: topic.pluck(:id),
      raw: "message body"
    ).exists?).to eq(true)
  end
  
  it 'updates a profile' do
    run_update(template, template['steps'][1]['id'], name: "Sally")
    expect(user.name).to eq('Sally')
  end
  
  it 'opens a composer' do
    template['steps'][0]['fields'] = [text_field, textarea_field]
    template['steps'][0]["actions"] = [open_composer_action]
    
    updater = run_update(template, nil,
      text: "Topic Title",
      textarea: "topic body"
    )
    
    expect(updater.result.blank?).to eq(true)              
    
    updater = run_update(template, template['steps'][1]['id'])
    
    expect(updater.result[:redirect_on_complete]).to eq(
      "/new-topic?title=Topic%20Title&body=topic%20body"
    )
  end
  
  it 'adds a user to a group' do          
    template['steps'][0]['fields'] = [dropdown_groups_field]
    template['steps'][0]["actions"] = [add_to_group_action]
              
    updater = run_update(template, nil, dropdown_groups: group.id)
    expect(group.users.first.username).to eq('angus')
  end
  
  it 're-routes a user' do
    template['steps'][0]["actions"] = [route_to_action]
    updater = run_update(template, nil, {})
    expect(updater.result[:redirect_on_next]).to eq(
      "https://google.com"
    )
  end
end
