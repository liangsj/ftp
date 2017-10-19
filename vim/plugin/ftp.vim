"map foo :call FtpSyncAll()<CR>
"map sou :source ~/.vim/plugin/ftp.vim<CR>
"map tt sssou
"author:liangshijian
let s:edit_directory_path = getcwd()
python << EOF
from ftplib import FTP
import vim,json,os,os.path
#打开ftp
def openFtp():
    host,port,name,passwd,selectToPath,selectFromPath = getConfig()
    try:
        ftp = FTP()
        ftp.connect(host,port)
        ftp.login(name,passwd)
    except:
        raise Exception("connect ftp faild")
    return ftp
    #读取ftp.conf
def getConfig():
    configPath = vim.eval("g:lsj_ftpConfig_path")
    confFile  = open(configPath)
    confjson = ""
    try:
        confjson = confFile.read()
    finally:
        confFile.close()
    confDic =  json.loads(confjson)
    editFilePath = vim.eval("s:edit_file_path")
    selectFromPath = ""
    selectToPath = ""
    ftpDic = confDic['ftp']
    port= str(ftpDic['port'])
    name= str(ftpDic['name'])
    passwd= str(ftpDic['passwd'])
    host= str(ftpDic['host'])
    for mapList in confDic['map']: 
        if editFilePath.startswith(mapList['from']):
            selectToPath = mapList['to']
            selectFromPath = mapList['from']
    if not selectToPath and not selectFromPath:
        raise Exception("your map from or to path has some error")
    return  host,port,name,passwd,selectToPath,selectFromPath
    #获得本地文件对应的ftp服务器的绝对路径
def getFtpFilePath():
    host,port,name,passwd,selectToPath,selectFromPath = getConfig()
    editFilePath = vim.eval("s:edit_file_path")
    ftpFilePath = editFilePath.replace(selectFromPath,selectToPath)
    return ftpFilePath
    #上传单文件
def uploadfile():
    host,port,name,passwd,selectToPath,selectFromPath = getConfig()
    ftp = openFtp()
    editFilePath = vim.eval("s:edit_file_path")
    ftpFilePath = getFtpFilePath()
    bufsize = 1024
    mkdirs(ftp,ftpFilePath,selectToPath)
    fp = open(editFilePath, 'rb')
    ftp.storbinary('STOR ' + ftpFilePath, fp, bufsize)
    print "update "+ editFilePath +" file to "+ftpFilePath +" successful"
    fp.close()
    ftp.close()
    #下载文件
def downfile():
    host,port,name,passwd,selectToPath,selectFromPath = getConfig()
    ftp = openFtp()
    editFilePath = vim.eval("s:edit_file_path")
    ftpFilePath = getFtpFilePath()
    bufsize = 1024
    fp = open(editFilePath, 'wb')
    ftp.retrbinary('RETR ' + ftpFilePath, fp.write)
    print "download "+ ftpFilePath +" file to "+ftpFilePath +" successful"
    fp.close()
    ftp.close()

def uploadallfiles():
    host,port,name,passwd,selectToPath,selectFromPath = getConfig()
    if not os.path.isdir(selectFromPath):
        raise Exception(selectFromPath +" is not dir")
    ftp = openFtp()
    ftp.cwd(selectToPath)
    rnUpfiles(ftp,selectFromPath,selectToPath)
    ftp.close()

def rnUpfiles(ftp,selectFromPath,selectToPath):
    preP = ftp.pwd()
    ftp.cwd(selectToPath)
    lt = os.listdir(selectFromPath)
    if lt:
        for f in os.listdir(selectFromPath):
            if f.startswith("."):
                continue
            if os.path.isdir(selectFromPath+f):
                prePath = ftp.pwd()
                ftp.cwd(selectToPath)
                if f not in ftp.nlst():
                    ftp.mkd(f)
                    print "make new direction "+ selectFromPath+f
                rnUpfiles(ftp,selectFromPath+f+os.sep,selectToPath+f+os.sep)
                ftp.cwd(prePath)
            elif os.path.isfile(selectFromPath+f):
                writeToRemote(ftp,selectFromPath+f,selectToPath)
                print "write local file:"+ selectFromPath+f +" To remote path "+selectToPath+f
    else:
        ftp.cwd(preP)
        return
        
def writeToRemote(ftp,localFile,ftpFilePath):
    p,f = os.path.split(localFile)
    ftpFilePath = ftpFilePath+f
    bufsize = 1024
    fp = open(localFile,'rb')
    ftp.storbinary('STOR ' + ftpFilePath, fp, bufsize)
    fp.close()   

def mkdirs(ftp,ftpFilePath,selectToPath):
    preftp = ftp.pwd()
    p,f = os.path.split(ftpFilePath)
    p = p.replace(selectToPath,"")
    pList = p.split(os.sep)
    try:
        ftp.cwd(selectToPath)
    except:
        raise Exception(selectToPath +" not exist in ftp")
    for pl in pList:
        if pl not in ftp.nlst() and pl != "":
            ftp.mkd(pl)
        ftp.cwd(pl)
    ftp.cwd(preftp) 
EOF
function! FtpSync()
    let s:edit_file_path = expand('%:p')
    exec "py uploadfile()"
endfunction

function! FtpSyncAll()
    let s:edit_file_path = expand('%:p')
    exec "py uploadallfiles()"
endfunction
function! FtpDown()
    let s:edit_file_path = expand('%:p')
    exec "py downfile()"
    exec ":e"
endfunction



command! FtpSync call FtpSync()
command! FtpDown call FtpDown()
command! FtpSyncAll call FtpSyncAll()
