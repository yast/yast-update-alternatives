# Copyright (c) 2016 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "yast"
require "ui/dialog"

Yast.import "UI"
Yast.import "Label"

module Y2Alternatives
  module Dialog
    # Dialog for displaying possible Choices for one particular Alternative.
    class EditAlternative < UI::Dialog
      MIN_WIDTH = 60
      MIN_HEIGHT = 20

      def initialize(alternative)
        textdomain "alternatives"
        @alternative = alternative
      end

      def dialog_content
        MinSize(
          MIN_WIDTH,
          MIN_HEIGHT,
          VBox(
            alternative_information,
            create_choices_table,
            RichText(Id(:slaves), ""),
            footer
          )
        )
      end

      def event_loop
        Yast::UI.ChangeWidget(:choices_table, :CurrentItem, @alternative.value)
        choices_table_handler
        super
      end

      def user_input
        event = Yast::UI.WaitForEvent
        return :set if event["ID"] == :choices_table && event["EventReason"] == "Activated"
        event["ID"]
      end

      def set_handler
        selected_choice = Yast::UI.QueryWidget(:choices_table, :CurrentItem)
        log.info("User selected the alternative: #{selected_choice}")
        @alternative.choose!(selected_choice)
        finish_dialog(true)
      end

      def auto_handler
        log.info("User selected \"Set automatic mode\" button")
        @alternative.automatic_mode!
        finish_dialog(true)
      end

      def choices_table_handler
        selected_choice = Yast::UI.QueryWidget(:choices_table, :CurrentItem)
        choice = @alternative.choices.find { |e| e.path == selected_choice }
        slaves = "<pre>" + choice.slaves + "</pre>"
        Yast::UI.ChangeWidget(:slaves, :Value, slaves)
      end

      def create_choices_table
        Table(
          Id(:choices_table),
          Opt(:notify, :immediate),
          Header(_("Choice"), _("Priority")),
          choices_list
        )
      end

      def choices_list
        @alternative.choices.map do |choice|
          Item(Id(choice.path), choice.path, choice.priority)
        end
      end

      def footer
        HBox(
          PushButton(Id(:set), _("Set choice")),
          PushButton(Id(:auto), _("Set automatic mode")),
          PushButton(Id(:cancel), Yast::Label.CancelButton)
        )
      end

      def alternative_information
        HBox(
          HSpacing(),
          VBox(
            Left(HBox(Label(_("Name:")), Label(@alternative.name))),
            Left(HBox(Label(_("Status:")), Label(@alternative.status))),
            Left(HBox(Label(_("Current choice:")), Label(@alternative.value)))
          )
        )
      end
    end
  end
end
