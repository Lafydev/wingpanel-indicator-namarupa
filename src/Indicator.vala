/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class AyatanaCompatibility.MetaIndicator : Wingpanel.Indicator {
    private Gee.HashSet<string> blacklist;
    private IndicatorFactory indicator_loader;
    private Gtk.FlowBox flow_box;

    public MetaIndicator () {
        Object (code_name: "ayatana_compatibility",
                display_name: _("Ayatana Compatibility"),
                description:_("Ayatana Compatibility Meta Indicator"));

        load_blacklist ();
        indicator_loader = new IndicatorFactory ();

        this.visible = true;
        var indicators = indicator_loader.get_indicators ();

        foreach (var indicator in indicators) {
            load_indicator (indicator);
        }
    }

    public override Gtk.Widget get_display_widget () {
        return new Gtk.Image.from_icon_name ("content-loading-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
    }

    private void load_indicator (IndicatorIface indicator) {
        var entries = indicator.get_entries ();

        foreach (var entry in entries) {
            create_entry (entry);
        }

        indicator.entry_added.connect (create_entry);
        indicator.entry_removed.connect (delete_entry);
    }

    private void create_entry (Indicator indicator) {
        if (blacklist.contains (indicator.name_hint ())) {
            return;
        }

        get_widget ();

        flow_box.add (indicator);
        flow_box.show_all ();
    }

    private void delete_entry (Indicator indicator) {
        get_widget ();

        foreach (var fbc in flow_box.get_children ()) {
            var child = ((Gtk.FlowBoxChild)fbc).get_child ();
            if (child is Indicator && ((Indicator)child).code_name == indicator.code_name) {
                child.destroy ();
                break;
            }
        }
    }

    public override Gtk.Widget? get_widget () {
        if (flow_box == null) {
            flow_box = new Gtk.FlowBox ();
            flow_box.margin = 6;
        }

        return flow_box;
    }

    public override void opened () {
        var box = get_widget ().get_parent ();
        if (box != null) {
            var popover = box.get_parent ();
            if (popover != null) {
                popover.width_request = 0;
            }
        }
    }

    public override void closed () {
    }

    private void load_blacklist () {
        blacklist = new Gee.HashSet<string> ();
        var blacklist_file = File.new_for_path ("/etc/wingpanel.d/ayatana.blacklist");
        foreach (var entry in get_restrictions_from_file (blacklist_file)) {
            blacklist.add (entry);
        }
    }

    private string[] get_restrictions_from_file (File file) {
        var restrictions = new string[] {};

        if (file.query_exists ()) {
            try {
                var dis = new DataInputStream (file.read ());
                string? line = null;

                while ((line = dis.read_line ()) != null) {
                    if (line.strip () != "") {
                        restrictions += line;
                    }
                }
            } catch (Error error) {
                warning ("Unable to load restrictions file %s: %s\n", file.get_basename (), error.message);
            }
        }

        return restrictions;
    }

}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION)
        return null;

    debug ("Activating AyatanaCompatibility Meta Indicator");
    var indicator = new AyatanaCompatibility.MetaIndicator ();
    return indicator;
}