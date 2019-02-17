import re

CLASSNAME = list()
INHERITEDCLASSNAME = list()
OBJECTLIST = list()
CONSTRUCTORS = list()

NUMOFCLASSES = 0
NUMOFINHERITED = 0
NUMOFCONSTRUCTOR = 0
NUMOFOPERATOROVERL = 0
NUMOFOBJECTS = 0

def removeComment(text):
    def replacer(match):
        s = match.group(0)
        if s.startswith('/') or s.startswith('"'):
            return " "  # note: a space and not an empty string
        else:
            return s
    pattern = re.compile(
        r'"(\\.|[^\\"])*"|//.*?$|/\*.*?\*/',
        re.DOTALL | re.MULTILINE
    )
    ttt = re.sub(pattern, replacer, text)
    # print(type(ttt))  
    return ttt

def classIdentfication(file):
    global NUMOFCLASSES
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        pattern = r'class\s+([A-Za-z_]\w*)\s*[\n\{]'
        classNames=re.findall(pattern,line)
        classNames = list(filter(None, classNames))
        if len(classNames)>0:
            NUMOFCLASSES += 1
        for itr in classNames:
            if itr not in CLASSNAME:
               CLASSNAME.append(itr)

def inheritedClass(file):
    lines=file.split("\n")
    global NUMOFINHERITED
    global NUMOFCLASSES
    # print(NUMOFCLASSES, NUMOFINHERITED)
    for line in lines:
        line += '\n'
        pattern = r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*\s*[\n\{]'
        inheritedClassNames=re.findall(pattern,line)
        # print(inheritedClassNames)
        if len(inheritedClassNames) > 0:
            NUMOFINHERITED = NUMOFINHERITED + 1
            NUMOFCLASSES = NUMOFCLASSES + 1
        for itr in inheritedClassNames:
            if itr not in INHERITEDCLASSNAME:
               INHERITEDCLASSNAME.append(itr)
               CLASSNAME.append(itr[0])
    # print(NUMOFCLASSES, NUMOFINHERITED)

def constructorFun(file):
    global NUMOFCONSTRUCTOR
    lines=file.split("\n")
    for line in lines:
        line += '\n'
        pattern = r'[^~]\b([A-Za-z_][A-Za-z\:_0-9]*)\s*\(([^)]*?)\)\s*[\n\{\:]'
        l1 = re.findall(pattern, line)            
        poss = False
        for declaration in l1:
            names = declaration[0].split('::')
            lenth = len(names)
            if names[lenth-1] in CLASSNAME and names[lenth-1] == names[0]:
                # print(names)
                poss = True
        if poss:
            NUMOFCONSTRUCTOR += 1
        
def objectFun(file):
    global NUMOFOBJECTS
    lines=file.split("\n")
    for line in lines:
        line += '\n'
        pattern=r'([A-Za-z_]\w*)\s*([\s\*]*[A-Za-z_\, ][A-Za-z0-9_\, \(\)]*)[^\n\{]*?;'
        classObjectList=re.findall(pattern, line)
        # if classObjectList:
        #     print(classObjectList)
        poss = False 
        # if classObjectList is None:
        #     continue
        for itr in classObjectList:
            if itr[0] in CLASSNAME:
                # print (itr)
                OBJECTLIST.append(itr[1])
                poss = True
            # elif itr[2] in CLASSNAME:
            #     OBJECTLIST.append(itr[3])
            #     poss = True
        if poss :
            NUMOFOBJECTS += 1


def overloadedFunction(file):
    global NUMOFOPERATOROVERL
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        pattern = r'operator\s*([\+\-\*\/]+)[^\{\;]*?[\n\{]'
        l1 = re.findall(pattern, line)
        if len(l1) > 0:
            NUMOFOPERATOROVERL += len(l1)

with open("input/input2.cpp", "r") as file:
    noCommentFile = removeComment(file.read())
    print("Assignment-2 Report : ")
    classIdentfication(noCommentFile)
    inheritedClass(noCommentFile)

    print("Classes              : ",NUMOFCLASSES)      # done
    print("Inherited classes    : ",NUMOFINHERITED)    # done
    # print (CLASSNAME)

    objectFun(noCommentFile)
    print("Objects Declaration  : ",NUMOFOBJECTS)      # done
    print (OBJECTLIST)

    overloadedFunction(noCommentFile)
    print("Operator Overloading : ", NUMOFOPERATOROVERL) # sort of done

    constructorFun(noCommentFile)
    print("Constructors         : ", NUMOFCONSTRUCTOR) # sort of done
