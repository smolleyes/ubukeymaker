#-*- coding: UTF-8 -*-
import os

version = "0.1"
APP_NAME = 'Ubukey'
LANG=os.environ.get('LANG').split('_')[0]
HOME=os.environ.get('HOME')
exec_path = os.path.dirname(os.path.abspath(__file__))
## gui
if ('/usr/local' in exec_path):
    data_path = os.path.join(exec_path,"/usr/local/share/ubukey")
elif ('/usr' in exec_path):
    data_path = os.path.join(exec_path,"/usr/share/ubukey")
else:
    data_path = os.path.join("../")

glade_path = os.path.join(data_path,"data/glade")
GLADE_FILE = os.path.join(glade_path,'gui.glade')
img_path = os.path.join(data_path,"img")
conf_path = os.path.join(HOME,'.config/ubukey')
conf_file = os.path.join(conf_path,'config')
distribs_ini = os.path.join(conf_path,'distribs.ini')
glade_path = os.path.join(data_path,"data/glade")
GLADE_FILE = os.path.join(glade_path,'gui.glade')



#if ('/usr' in exec_path):
scripts_path=os.path.join(data_path,'scripts')
#else:
#    scripts_path=os.path.join(os.path.dirname(exec_path),'scripts')

## log settings
LOG=os.path.join(HOME,'.config/ubukey/logs/log')
LOGDIR=os.path.dirname(LOG)
