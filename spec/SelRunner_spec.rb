require "spec_helper"


describe SelRunner do

  describe '#Platform Updater' do
    # Builds a cell instance
    it 'Builds an instance' do
      args = {
         System: "OS_X_Mavericks",
         Browser: "firefox_40.0",
         Device: nil,
         os: "os X",
         osver: "Mavericks",
         bname: "firefox",
         bver: "40.0",
       }
      results = SelRunner::Platforms.build_instance(args)
      expect(results).to_not eql(false)
    end

  end #end master control desc
end #end the spec
