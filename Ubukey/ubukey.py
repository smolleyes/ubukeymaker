#!/usr/bin/env python
#-*- coding: UTF-8 -*-

import pygtk
pygtk.require('2.0')
import gtk
import gtk.glade
import os, re, time
import Xlib
import Xlib.display
from Xlib import X
from subprocess import Popen, PIPE

## own import
from lib.loader import *
from lib.terminal import VirtualTerminal
from lib.distribs import Distribs
from lib.constants import *
from lib.functions import get_dist_env

class Ubukey_gui(object):
    def __init__(self):
        if os.getuid() == 0:
            self.error_dialog("Ubukey can't start as root user ...",None)
            exit()
        ## set the gladexml file
        self.gladexml = gtk.glade.XML(GLADE_FILE, None ,APP_NAME)
        self.selected_dist = None
        ## the main window and properties
        self.window = self.gladexml.get_widget("main_window")
        self.window.set_resizable(1)
        self.window.set_position("center")
        ## glade widgets
        self.eventbox = self.gladexml.get_widget("eventbox1")
        self.vt_container = self.gladexml.get_widget("vt_container")
        self.run_btn_label = self.gladexml.get_widget("run_btn_label")
        self.run_btn_img = self.gladexml.get_widget("run_btn_img")
        self.run_btn_state = "stopped"
        ## vbox btn
        self.vbox_img = self.gladexml.get_widget('vbox_img')
        img = gtk.gdk.pixbuf_new_from_file_at_scale(os.path.join(data_path,'images/vbox.png'), 24, 24, 1)
        self.vbox_img.set_from_pixbuf(img)
        ## dist logo
        self.distlogo = self.gladexml.get_widget('distlogo_img')
        
        ## dist list treeview
        self.dist_scroll = self.gladexml.get_widget("dist_scroll")
        self.dist_model = gtk.ListStore(str, str)

        self.distTree = gtk.TreeView()
        self.distTree.set_model(self.dist_model)
        renderer = gtk.CellRendererText()
        titleColumn = gtk.TreeViewColumn("Name", renderer, text=0)
        titleColumn.set_min_width(200)
        pathColumn = gtk.TreeViewColumn()

        self.distTree.append_column(titleColumn)
        self.distTree.append_column(pathColumn)

        ## setup the scrollview
        self.columns = self.distTree.get_columns()
        self.columns[0].set_sort_column_id(1)
        self.columns[1].set_visible(0)
        self.dist_scroll.add(self.distTree)
        self.distTree.connect('cursor-changed',self.get_selected_dist)

        ## add socket for Xephyr
        self.socket = gtk.Socket()
        self.socket.show()
        self.eventbox.add(self.socket)
        ## signals
        dic = {"on_destroy_event" : self.exit,
               "on_delete_event" : self.exit,
               "on_start_btn_clicked" : self.set_startdist_btn_state,
               "on_newdist_btn_clicked" : self.new_dist,
               "on_removedist_btn_clicked" : self.remove_dist,
               "on_export_btn_clicked" : self.export_dist,
               "on_vbox_btn_clicked" : self.start_vbox,
               "on_bootcd_btn_clicked" : self.gen_bootcd,
               "on_clone_btn_clicked" : self.clone_dist,
               }
        
        self.gladexml.signal_autoconnect(dic)
        ## calculate default window size (Xephyr s not resizable)
        width = gtk.gdk.screen_width()
        height = gtk.gdk.screen_height()
        self.window.set_default_size((width - 50), (height - 80))
        
        ##  start gui widgets
        self.start_gui()
    
    def start_gui(self):
        try:
            main_dist_path,dist_list = scan_dist_path()
        except:
            path = checkConf()
            return self.start_gui()
        self.window.show_all()
        self.load_distribs_xml()
        self.start_Xephyr()
        self.startVt()
        gtk.main()

    def error_dialog(self,message, parent = None):
        """Displays an error message."""
        dialog = gtk.MessageDialog(parent = parent, type = gtk.MESSAGE_ERROR, buttons = gtk.BUTTONS_OK, flags = gtk.DIALOG_MODAL)
        dialog.set_markup(message)
        dialog.set_position('center')
        result = dialog.run()
        dialog.destroy()
                   
    def start_Xephyr(self):
        xid = self.socket.get_id()
        lockfile="/tmp/.X5-lock"
        if os.path.exists(lockfile):
            os.remove(lockfile)
        os.system('killall -9 Xephyr')
        cmd = "Xephyr :5 -title ubukey-xephyr \
        -ac -s 120 \
        -keybd ephyr,,xkblayout=%s,xkbmodel=evdev -parent %s & sleep 4 " % (LANG,xid)
        self.xephyr_pipe = Popen(cmd,shell=True)
        
    def get_selected_dist(self,widget):
        """return the path of the selected dist in the gui treeview"""
        selected = self.distTree.get_selection()
        self.dist_iter = selected.get_selected()[1]
        ## else extract needed metacity's infos
        self.selected_dist = self.dist_model.get_value(self.dist_iter, 0)
        self.selected_dist_path = self.dist_model.get_value(self.dist_iter, 1)
        session = get_dist_env(self.selected_dist,self.selected_dist_path)
        if session and not session == "":
            img = os.path.join(data_path,"images/logo_%s.png" % session)
            self.distlogo.set_from_file(img)
        
    def set_startdist_btn_state(self,widget):
        if self.run_btn_state == "stopped":
            self.distribs.start()
        elif self.run_btn_state == "started":
            self.distribs.stop()
        
    def startVt(self):
        self.vt = VirtualTerminal(LOG)
        self.vt_container.add(self.vt)
        self.vt.show()
        
    def load_distribs_xml(self):
        self.distribs = Distribs(self)
        self.distribs.update_list()
        
    def new_dist(self,widget=None):
        self.distribs.new_dist()
        
    def export_dist(self,widget):
        self.distribs.export_dist()
        
    def remove_dist(self,widget):
        self.distribs.remove_dist()
        
    def start_vbox(self,widget):
        self.distribs.start_vbox()
        
    def gen_bootcd(self,widget):
        self.distribs.gen_bootcd()
        
    def clone_dist(self,widget):
        self.distribs.clone_dist()
        
    def exit(self,window=None,event=None):
        os.system('killall -9 Xephyr')
        gtk.main_quit()
        
    def pkg(self,widget):
        self.vt.run_command('/bin/bash ' + data_path +'/scripts/dialog.sh')
        
if __name__ == "__main__":
    checkConf()
    gui = Ubukey_gui()
