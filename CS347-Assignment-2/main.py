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


# add multilines declaration but add single count
# def classIdentfication(file):
#     global NUMOFCLASSES
#     lines = file.split("\n")
#     for line in lines:
#         pattern = r'class\s+([A-Za-z_]\w*)'
#         classNames=re.findall(pattern,line)
#         classNames = list(filter(None, classNames))
#         pattern = r'class\s+([A-Za-z_]\w*)\s*;'
#         classDec=re.findall(pattern,line)
#         classDec = list(filter(None, classDec))
#         # poss = False
#         classDef = []
#         for x in classNames:
#             if x in classDec:
#                 classDec.remove(x)
#             else : 
#                 classDef.append(x)
#         for itr in classDef:
#             if itr not in CLASSNAME:
#                CLASSNAME.append(itr)
            #    poss = True
        
    # print (CLASSNAME)
    # return len(CLASSNAME)


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
    # print(NUMOFCLASSES, NUMOFINHERITED)


def constructorFun(file):
    global NUMOFCONSTRUCTOR
    lines=file.split("\n")
    for line in lines:
        line += '\n'
        pattern = r'([A-Za-z_][A-Za-z\:_0-9]*)\s*\(([^)]*?)\)\s*[\n\{]'
        l1 = re.findall(pattern, line)
        poss = False
        for declaration in l1 :
            names = declaration[0].split(':')
            if names[0] in CLASSNAME:
                poss = True
        if poss:
            NUMOFCONSTRUCTOR += 1
        

def objectFun(file):
    global NUMOFOBJECTS
    lines=file.split("\n")
    for line in lines:
        pattern=r'([A-Za-z_]\w*)\s*\**\s+([A-Za-z_]\w*) | ([A-Za-z_]\w*)\s+\**\s*([A-Za-z_]\w*)'
        classObjectList=re.findall(pattern,line)
        poss = False
        for itr in classObjectList:
            if itr[0] in CLASSNAME:
                OBJECTLIST.append(itr[1])
                poss = True
            elif itr[2] in CLASSNAME:
                OBJECTLIST.append(itr[3])
                poss = True
        if poss :
            NUMOFOBJECTS += 1


def overloadedFunction(file):
    global NUMOFOPERATOROVERL
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        # pattern = r'class'
        # pattern = r'([A-Za-z_]\w*)\s*(?:&|(?:\*|\s)+)?\s*operator|(?:([A-Za-z_]\w*)\s*(?:&|(?:\*|\s)+)?\s*operator.*?;)'
        # overloadfunctions=re.findall(pattern,line)
        # If overloadfunctions is not-empty, increment
        # pa = r'operator\s*([\+\-\*\/]+)[^\{\;]*'
        pattern = r'operator\s*([\+\-\*\/]+)[^\{\;]*?[\n\{]
        l1 = re.findall(pattern, line)
        # pattern = r'operator\s*([\+\-\*\/]+)[^\{\;]*?;'
        # l2 = re.findall(pattern, line)
        # poss = False
        # l3 = [x for x in l1 if x not in l2]
        # for declaration in l3:
        #     names = declaration[0].split(':')
        #     if names[0] in CLASSNAME:
        #         poss = True
        if len(l1) > 0:
            NUMOFOPERATOROVERL += 1


with open("input/file.cpp", "r") as file:
    noCommentFile = removeComment(file.read())
    print("Assignment-2 Report : ")
    classIdentfication(noCommentFile)
    inheritedClass(noCommentFile)

    print("Classes              : ",NUMOFCLASSES)      # done
    print("Inherited classes    : ",NUMOFINHERITED)    # done

    objectFun(noCommentFile)
    print("Objects Declaration  : ",NUMOFOBJECTS)      # done

    overloadedFunction(noCommentFile)
    print("Operator Overloading : ", NUMOFOPERATOROVERL) # sort of done

    constructorFun(noCommentFile)
    print("Constructors         : ", NUMOFCONSTRUCTOR) # sort of done

# r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*'
# r'([A-Za-z_]\w*)\:\:([A-Za-z_]\w*)\s*\(.*\)[^;]+|([A-Za-z_]\w*)\s*\(.*\)[^;]+'
# r'([A-Za-z_]\w*)\s*\*?\s+([A-Za-z_]\w*) | ([A-Za-z_]\w*)\s+\*?\s*([A-Za-z_]\w*)'