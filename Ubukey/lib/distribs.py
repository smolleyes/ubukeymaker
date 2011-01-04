#!/usr/bin/env python
#-*- coding: UTF-8 -*-

## own import
from constants import *
from functions import *
import time
from subprocess import Popen, PIPE

class NoSourceError(Exception): pass

class Distribs(object):
    def __init__(self,gui):
        self.ini = distribs_ini
        self.gui = gui
        self.username = os.environ.get('USERNAME')
        if not self.username:
            self.username = os.environ.get('USER')
            
    def start(self):
        self.chroot_script = os.path.join(scripts_path,'dochroot.sh')
        crun = os.popen("ps aux | grep -e "+scripts_path+'/dochroot'" | grep -v 'grep'").read().strip()
        xrun = os.popen("ps aux | grep -e "+scripts_path+'/startchroot'" | grep -v 'grep'").read().strip()
        if not crun == '' or not xrun == '':
            print "a session is already running"
            return
        
        self.gui.run_btn_label.set_text("Stop")
        self.gui.run_btn_img.set_from_stock(gtk.STOCK_STOP,gtk.ICON_SIZE_BUTTON)
        self.gui.run_btn_state = "started"
        self.gui.vt.log("distro started")
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.chroot_script, self.gui.selected_dist_path, self.username))
        self.pid = os.popen("ps aux | grep -e 'dochroot' | grep -v 'grep'").read().strip()
        while 1:
            t = os.popen("ps aux | grep -e 'bash "+scripts_path+'/dochroot'" | grep -v 'grep'").read().strip()
            if not t == '':
                time.sleep(5)
            else:
                if self.gui.run_btn_state == "started":
                    self.stop()
                break
        
    def stop(self):
        t=os.popen("ps aux | grep 'startchroot' | grep -v 'grep' | awk '{print $2}' | xargs").read().strip()
        if t and t != '':
            r = os.system("gksu 'kill -9 %s'" % t)
            if not r == 256:
                return
        self.gui.run_btn_label.set_text("Start")
        self.gui.run_btn_img.set_from_stock(gtk.STOCK_MEDIA_PLAY,gtk.ICON_SIZE_BUTTON)
        self.gui.run_btn_state = "stopped"
        self.gui.vt.log("distro stopped")
    
    def update_list(self):
        self.main_dist_path,dist_list = scan_dist_path()
        print "updating distrib list..."
        self.parser = Parser(self.ini)
        for dir in dist_list:
            dist_name = os.path.basename(dir)
            dist_conf = os.path.join(dir,'config')
            if not self.parser.has_section(dist_name):
                self.parser.add_section(dist_name)
                dist_parser = Parser(dist_conf)
                for key,value in dist_parser.items(dist_name):
                    self.parser.set(dist_name,key,value)
        write_ini(self.parser,self.ini)
        self.gui.dist_model.clear()
        for dist in self.parser.sections():
            self.add_model(dist)
            
    def add_model(self,dist):
        self.iter = self.gui.dist_model.append()
        self.gui.dist_model.set(self.iter,
        0, dist,
        1, os.path.join(self.main_dist_path,'distribs',dist),
        )
    
    def new_dist(self):
        self.create_script = os.path.join(scripts_path,'create_dist.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.create_script,
                                                             self.main_dist_path,
                                                             self.username))
        self.update_list()
        
    def remove_dist(self):
        quest = yesno("remove a distribution", "Remove your distribution %s installed in :\n%s  ?" % (self.gui.selected_dist,self.gui.selected_dist_path))
        if quest == "No":
            return
        self.remove_script = os.path.join(scripts_path,'remove_dist.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.remove_script,
                                                          self.gui.selected_dist,
                                                          self.gui.selected_dist_path))
        self.parser.remove_section(self.gui.selected_dist)
        write_ini(self.parser,self.ini)
        self.gui.dist_model.remove(self.gui.dist_iter)
        
    def export_dist(self):
        self.export_script = os.path.join(scripts_path,'export_dist.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.export_script,
                                                          self.gui.selected_dist,
                                                          self.gui.selected_dist_path))
        
    def start_vbox(self):
        self.vbox_script = os.path.join(scripts_path,'vbox.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.vbox_script,
                                                          self.gui.selected_dist,
                                                          self.gui.selected_dist_path))
        
    def gen_bootcd(self):
        self.bootcd_script = os.path.join(scripts_path,'mkbootcd.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.bootcd_script,
                                                          self.gui.selected_dist,
                                                          self.gui.selected_dist_path))
        
    def clone_dist(self):
        self.clone_script = os.path.join(scripts_path,'clone_dist.sh')
        self.gui.vt.run_command('gksu /bin/bash %s %s %s %s' % (self.clone_script,
                                                             self.gui.selected_dist,
                                                             self.gui.selected_dist_path,
                                                             self.main_dist_path))
        self.update_list()
        
    
        
                                
