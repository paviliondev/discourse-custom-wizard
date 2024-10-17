# frozen_string_literal: true

describe ApplicationController do
  fab!(:user) do
    Fabricate(:user, username: "angus", email: "angus@email.com", trust_level: TrustLevel[3])
  end
  let(:wizard_template) { get_wizard_fixture("wizard") }
  let(:permitted_json) { get_wizard_fixture("wizard/permitted") }

  before do
    CustomWizard::Template.save(wizard_template, skip_jobs: true)
    @template = CustomWizard::Template.find("super_mega_fun_wizard")
  end

  context "with signed in user" do
    before { sign_in(user) }

    context "who is required to complete wizard" do
      before do
        user.custom_fields["redirect_to_wizard"] = "super_mega_fun_wizard"
        user.save_custom_fields(true)
      end

      it "does not redirect if wizard if no after setting is enabled" do
        get "/"
        expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
      end

      context "after signup enabled" do
        before do
          @template["after_signup"] = true
          CustomWizard::Template.save(@template)
        end

        it "does not redirect if wizard does not exist" do
          CustomWizard::Template.remove(@template[:id])
          get "/"
          expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
        end

        it "redirects if user is required to complete a wizard" do
          get "/"
          expect(response).to redirect_to("/w/super-mega-fun-wizard")
        end

        it "does not redirect if wizard is subsequently disabled" do
          get "/"
          expect(response).to redirect_to("/w/super-mega-fun-wizard")

          @template["after_signup"] = false
          CustomWizard::Template.save(@template)

          get "/"
          expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
        end

        it "saves original destination of user" do
          get "/", headers: { "REFERER" => "/t/2" }
          expect(
            CustomWizard::Wizard.create(@template["id"], user).submissions.first.redirect_to,
          ).to eq("/t/2")
        end
      end

      include ActiveSupport::Testing::TimeHelpers
      context "after time enabled" do
        before do
          @template["after_time"] = true
          @template["after_time_scheduled"] = (Time.now + 3.hours).iso8601
          CustomWizard::Template.save(@template)
        end

        context "when time hasn't passed" do
          it "does not redirect" do
            get "/"
            expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
          end
        end

        context "when time has passed" do
          def run_job!
            travel_to Time.now + 4.hours
            MessageBus.expects(:publish).at_least_once
            Jobs::SetAfterTimeWizard.new.execute(
              Jobs::SetAfterTimeWizard.jobs.first["args"].first.symbolize_keys,
            )
          end

          it "redirects if time has passed" do
            run_job!
            get "/"
            expect(response).to redirect_to("/w/super-mega-fun-wizard")
          end

          context "when permitted is set" do
            before do
              enable_subscription("business")
              @template["permitted"] = permitted_json["permitted"]
              CustomWizard::Template.save(@template.as_json)
            end

            context "when user is in permitted group" do
              it "redirects user" do
                run_job!
                get "/"
                expect(response).to redirect_to("/w/super-mega-fun-wizard")
              end
            end

            context "when user is not in permitted group" do
              before { Group.find(13).remove(user) }

              it "does not redirect user" do
                run_job!
                user.trust_level = TrustLevel[2]
                user.save!
                get "/"
                expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
              end

              it "does not redirect if user is an admin" do
                run_job!
                user.trust_level = TrustLevel[2]
                user.admin = true
                user.save!
                get "/"
                expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
              end
            end
          end

          context "when user has completed the wizard" do
            before do
              @template[:steps].each do |step|
                CustomWizard::UserHistory.create!(
                  action: CustomWizard::UserHistory.actions[:step],
                  actor_id: user.id,
                  context: @template[:id],
                  subject: step[:id],
                )
              end
            end

            it "does not redirect" do
              run_job!
              get "/"
              expect(response).not_to redirect_to("/w/super-mega-fun-wizard")
            end
          end

          context "when after_time_groups is set" do
            fab!(:group)

            before do
              enable_subscription("business")
              @template["after_time_groups"] = [group.name]
              CustomWizard::Template.save(@template.as_json)
            end

            context "when user is in group" do
              before { group.add(user) }

              it "redirects user" do
                run_job!
                get "/"
                expect(response).to redirect_to("/w/super-mega-fun-wizard")
              end
            end

            context "when user is not in group" do
              before { group.remove(user) }

              it "does not redirect user" do
                run_job!
                get "/"
                expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
              end

              it "does not redirect if user is an admin" do
                run_job!
                user.admin = true
                user.save!
                get "/"
                expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
              end
            end
          end
        end
      end
    end

    context "who is not required to complete wizard" do
      it "does nothing" do
        get "/"
        expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
      end
    end
  end

  context "with guest" do
    it "does nothing" do
      get "/"
      expect(response).to_not redirect_to("/w/super-mega-fun-wizard")
    end
  end
end
