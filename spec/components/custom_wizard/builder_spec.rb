# frozen_string_literal: true

require 'rails_helper'

describe CustomWizard::Builder do
  it "returns a wizard when enabled" do
    ## implement enabled site setting first
  end
  
  it "returns nothing when disabled" do
    ## implement enabled site setting first
  end
  
  it 'returns a wizard with prefilled data if user has partially completed' do
  
  end
  
  it 'returns a wiard with no prefilled data if options include reset' do
  
  end
  
  it 'returns nothing if the multiple submissions are disabled and user has completed' do
    
  end
  
  it 'returns nothing if the user is not permitted to see it' do
  
  end
  
  context 'building steps' do
    it 'returns step data correctly' do
      
    end
    
    it 'saves permitted params' do
    
    end
    
    it 'ensures required data is present' do
    
    end
  end
  
  context 'building fields' do
    it 'returns field data correctly' do
    
    end
    
    it 'returns checkbox fields correctly' do
    
    end
    
    it 'returns upload fields correctly' do
    
    end
    
    it 'returns category fields correctly' do
    
    end
    
    it 'returns tag fields correctly' do
    
    end
    
    it 'returns custom dropdown fields correctly' do
    
    end
    
    it 'returns translated dropdown fields correctly' do
    
    end
    
    it 'returns preset dropdown fields correctly' do
    
    end
    
    it 'applies preset dropdown filters correctly' do
    
    end
    
    it 'prefils profile data correctly' do
    
    end
  end
  
  context 'on update' do
    context 'validation' do
      it 'applies min length correctly' do
      
      end
      
      it 'standardises boolean entries' do
      
      end
      
      it 'requires required fields' do
        ## this may require additional work?
      end
      
      context 'submisisons' do
        it 'saves submissions' do
        
        end
        
        it "doesn't save submissions if disabled" do
        
        end
      end
    end
    
    context 'custom_step_handlers' do
      it 'runs custom step handlers' do
      
      end
    end
    
    context 'actions' do
      it 'runs all actions attached to a step' do
        
      end
      
      it 'interpolates wizard and user data correctly' do
      
      end
      
      it 'creates a topic' do
      
      end
      
      it 'sends a message' do
      
      end
      
      it 'doesnt sent a message if the required data is not present' do
      
      end
      
      it 'updates a profile' do
      
      end
      
      it 'calls an api' do
      
      end
      
      it 'opens a composer' do
      
      end
      
      it 'adds a user to a group' do
      
      end
      
      it 're-routes a user' do
        
      end
    end
  end
end