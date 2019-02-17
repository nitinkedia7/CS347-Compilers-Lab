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
    noCommentFile = re.sub(pattern, replacer, text)
    return noCommentFile

# def remove_alias(text):
#   pattern = r'(#define .*?)[\n$]|(typedef [^\;]*?);'
#   defines = re.findall(pattern, text)
#   no_alias_file = ''
#   for iter in defines:
#       x = iter.split(' ')
#       repl = ' '.join(x[2:])
#       repl = '\b'+repl+'\b'
#       repl = repl('\,', '\,', x[1])
#       no_alias_file = re.sub(x[1], repl, text)
#   return no_alias_file


def classDefinition(file):
    global NUMOFCLASSES
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        flag1 = False
        flag2 = False
        # pattern = r'class\s+([A-Za-z_]\w*)(?:\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*)?[\s]*[\n\{]'
        pattern1 = r'class\s+([A-Za-z_]\w*)[\s]*[\n\{]'
        classNames = re.findall(pattern1, line)
        pattern2 = r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*\s*[\n\{]'
        inheritedClassNames = re.findall(pattern2, line)
        classNames = list(filter(None, classNames))
        if len(classNames) > 0:
            flag1 = True
        if len(inheritedClassNames) > 0:
            flag2 = True
        if (flag1 or flag2):
            NUMOFCLASSES+=1
        for itr in classNames:
            if itr not in CLASSNAME:
                CLASSNAME.append(itr)


def inheritedClass(file):
    lines = file.split("\n")
    global NUMOFINHERITED
    global NUMOFCLASSES
    for line in lines:
        line += '\n'
        pattern = r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*\s*[\n\{]'
        inheritedClassNames = re.findall(pattern, line)
        # print(inheritedClassNames)
        if len(inheritedClassNames) > 0:
            NUMOFINHERITED = NUMOFINHERITED + 1
            # NUMOFCLASSES = NUMOFCLASSES + 1
        for itr in inheritedClassNames:
            if itr not in INHERITEDCLASSNAME:
                INHERITEDCLASSNAME.append(itr)
                CLASSNAME.append(itr[0])
    # print(NUMOFCLASSES, NUMOFINHERITED)


def constructorDefinition(file):
    global NUMOFCONSTRUCTOR
    lines = file.split("\n")
    for line in lines:
        # line=" "+line
        line += '\n'
        pattern = r'(?:[^~]|^)\b([A-Za-z_][A-Za-z\:_0-9]*)\s*\(([^)]*?)\)\s*[\n\{\:]'
        # pattern = r'\b([^\~][A-Za-z\:_0-9]*)\s*\(([^)]*?)\)\s*[\n\{\:]'
        l1 = re.findall(pattern, line)
        poss = False
        for declaration in l1:
            names = declaration[0].split('::')
            lenth = len(names)
            if names[lenth-1] in CLASSNAME and names[lenth-1] == names[0]:
                # print(names)
                # print(declaration)
                poss = True
        if poss:
            NUMOFCONSTRUCTOR += 1


def objectDeclaration(file):
    global NUMOFOBJECTS
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        # pattern = r'([A-Za-z_]\w*)[\s|\*](\,?[\s|\*]*[A-Za-z_]\w*.*?[;\,])+'
        pattern = r'([A-Za-z_]\w*)\s*([\s\*]*[A-Za-z_\,\s][A-Za-z0-9_\,\[\]\s\(\)]*)[^\n\{]*?;'
        classObjectList = re.findall(pattern, line)
        # print(classObjectList)
        poss = False
        for itr in classObjectList:
            if itr[0] in CLASSNAME:
                OBJECTLIST.append(itr[1])
                # print(itr)
                poss = True
        if poss:
            NUMOFOBJECTS += 1


def overloadedFunction(file):
    global NUMOFOPERATOROVERL
    lines = file.split("\n")
    for line in lines:
        line += '\n'
        pattern = r'operator\b([\+\-\/\<\>\=\:\[\]\s])*[^\{\;]*?[\n\{]'
        # pattern = r'operator\b[^\{\;]*?[\n\{]'
        l1 = re.findall(pattern, line)
        if len(l1) > 0:
            NUMOFOPERATOROVERL += 1


file_name = input("Enter file name : ")
file_name = "input/"+file_name
with open(file_name, "r") as file:
    noCommentFile = removeComment(file.read())
    classDefinition(noCommentFile)
    inheritedClass(noCommentFile)

    print("Classes              : ", NUMOFCLASSES)
    print("Inherited classes    : ", NUMOFINHERITED)
    # print (CLASSNAME)

    objectDeclaration(noCommentFile)
    print("Objects Declaration  : ", NUMOFOBJECTS)
    # print(OBJECTLIST)

    overloadedFunction(noCommentFile)
    print("Operator Overloading : ", NUMOFOPERATOROVERL)

    constructorDefinition(noCommentFile)
    print("Constructors         : ", NUMOFCONSTRUCTOR)
