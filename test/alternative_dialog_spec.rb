require_relative "spec_helper.rb"
require "update-alternatives/UI/alternative_dialog"
require "update-alternatives/model/alternative"

describe UpdateAlternatives::AlternativeDialog do
  def mock_ui_events(*events)
    allow(Yast::UI).to receive(:UserInput).and_return(*events)
  end

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
    allow(Yast::UI).to receive(:QueryWidget).with(:choices_table, :CurrentItem)
      .and_return(alternative.value)
  end

  subject(:alternative) do
    UpdateAlternatives::Alternative.new(
      "editor",
      "manual",
      "/usr/bin/nano",
      [
        UpdateAlternatives::Alternative::Choice.new("/usr/bin/nano", "20", "nano slaves\n line2"),
        UpdateAlternatives::Alternative::Choice.new("/usr/bin/vim", "30", "vim slaves\n line2")
      ]
      )
  end

  describe "#run" do
    it "selects the Alternative's current choice and show his slaves" do
      expect(Yast::UI).to receive(:ChangeWidget)
        .with(:choices_table, :CurrentItem, alternative.value)
      expect(Yast::UI).to receive(:ChangeWidget)
        .with(:slaves, :Value, "<pre>" + alternative.choices.first.slaves + "</pre>")
      mock_ui_events(:cancel)
      UpdateAlternatives::AlternativeDialog.new(alternative).run
    end
  end

  describe "#auto_handler" do
    it "calls Alternative#automatic_mode!" do
      mock_ui_events(:auto)
      expect(alternative).to receive(:automatic_mode!)
      UpdateAlternatives::AlternativeDialog.new(alternative).run
    end
  end

  describe "#set_handler" do
    it "calls Alternative#choose!" do
      mock_ui_events(:set)
      expect(alternative).to receive(:choose!)
      UpdateAlternatives::AlternativeDialog.new(alternative).run
    end

    it "calls Alternative#choose! with the path of the selected choice in the table" do
      mock_ui_events(:set)
      allow(Yast::UI).to receive(:QueryWidget).with(:choices_table, :CurrentItem)
        .and_return(alternative.value, "/usr/bin/vim")
      expect(alternative).to receive(:choose!).with("/usr/bin/vim")
      UpdateAlternatives::AlternativeDialog.new(alternative).run
    end
  end

  describe "#cancel_handler" do
    it "doesn't modify the alternative" do
      mock_ui_events(:cancel)
      expect(alternative).to_not receive(:choose!)
      expect(alternative).to_not receive(:automatic_mode!)
      UpdateAlternatives::AlternativeDialog.new(alternative).run
    end
  end
end
