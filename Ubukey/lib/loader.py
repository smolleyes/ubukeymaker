#!/usr/bin/env python
#-*- coding: UTF-8 -*-

## own import
from constants import *
from functions import *
import os,gtk,sys,re

def checkConf():
    ## CONF FILE
    if not path_exist(conf_path):
        path = FirstRun()
        if path and path_exist(path):
            os.makedirs(conf_path, 0755)
            print "selected path : %s" % path
            listdir = ("distribs","isos","temp","addons/lucid",
                       "addons/lucid/gnome","addons/lucid/kde4",
                       "addons/lucid/xfce4","addons/lucid/lxde",
                       "addons/perso","addons/maverick",
                       "addons/maverick/gnome","addons/maverick/kde4",
                       "addons/maverick/xfce4","addons/maverick/lxde",
                       "addons/custom","addons/all")
            for d in listdir:
                target = os.path.join(path,d)
                if not path_exist(target):
                    create_dir(target)
            parser = Parser(conf_file)
            parser.add_section('ubukey')
            parser.set('ubukey', 'dist_path', path)
            parser.set('ubukey', 'kernel', run_cmd('uname -r'))
            parser.set('ubukey', 'dist', run_cmd('lsb_release -cs'))
            write_ini(parser,conf_file)
        else:
            exit()
    ## load config and verify main distrib dir
    main_dist_path,dist_list = scan_dist_path()
    if not os.access(main_dist_path, os.R_OK):
        error_dialog("Votre dossier de distributions :\n%s \nn'est pas accessible, pas monté ou supprimé (recréez le)..." % main_dist_path)
        sys.exit()
        
    ## LOGS
    if not path_exist(LOGDIR):
        create_dir(LOGDIR)
    ## clean the log file
    if path_exist(LOG):
        os.remove(LOG)
        
def FirstRun():
    ## select a dir for the distributions
    dialog = create_folderchooser_open('Select a folder for your distributions')
    result = dialog.run()
    if result != gtk.RESPONSE_OK:
        dialog.destroy()
        return
    
    path = dialog.get_filename()
    cpath = os.getcwd()
    dialog.destroy()
    # verify the partition rights
    if (re.search(os.path.dirname(cpath),path)):
		print "Please do not choose the ubukey's source folder as basedir !\n"
		return FirstRun()
	
    path_part = os.popen("df '%s' | grep /dev | awk '{print $1}'" % path, 'r').read().strip()
    path_check = os.popen("mount | grep '%s' | grep -E '(ntfs|vfat|nosuid|noexec|nodev)'" % path_part, 'r').read().strip()
    if (path_check != ''):
        print "Please select another folder (no ntfs/fat partitions or partitions mounted with nosuid/nodev/noexec options or root protected...please correct fstab or choose another partition!)"
        return FirstRun()
    ## ok return the path
    return path
    

