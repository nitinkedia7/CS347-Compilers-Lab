import re

CLASSNAME = list()
INHERITEDCLASSNAME = list()
OBJECTLIST = list()

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
def classIdentfication(file):
    lines = file.split("\n")
    for line in lines:
        pattern = r'class\s+([A-Za-z_]\w*)'
        classNames=re.findall(pattern,line)
        for itr in classNames:
            if itr not in CLASSNAME:
               CLASSNAME.append(itr)
    # print (CLASSNAME)
    return len(CLASSNAME)

def inheritedClass(file):
    lines=file.split("\n")
    for line in lines:
        pattern = r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*'
        inheritedClassNames=re.findall(pattern,line)
        for itr in inheritedClassNames:
            if itr not in INHERITEDCLASSNAME:
               INHERITEDCLASSNAME.append(itr)
    return len(INHERITEDCLASSNAME)


def constructorFun(file):
    lines=file.split("\n")
    for line in lines:
        pattern=r'[A-Za-z_]\w*\:\:[A-Za-z_]\s*\([^;]|([A-Za-z_]\w*)\s*\([^;]'
        constructors=re.findall(pattern,line)
        

def objectFun(file):
    lines=file.split("\n")
    for line in lines:
        pattern=r'([A-Za-z_]\w*)\s*\*?\s+([A-Za-z_]\w*) | ([A-Za-z_]\w*)\s+\*?\s*([A-Za-z_]\w*)'
        classObjectList=re.findall(pattern,line)
        for itr in classObjectList:
            # print (itr)
            if itr[0] in CLASSNAME:
                OBJECTLIST.append(itr[1])
            elif itr[2] in CLASSNAME:
                OBJECTLIST.append(itr[3])
    return len(OBJECTLIST)

def overloadedFunction(file):
    lines = file.split("\n")
    for line in lines:
        # pattern = r'class'
        pattern = r'([A-Za-z_]\w*)\s*(?:&|(?:\*|\s)+)?\s*operator|(?:([A-Za-z_]\w*)\s*(?:&|(?:\*|\s)+)?\s*operator.*?;)'
        overloadfunctions=re.findall(pattern,line)
        # If overloadfunctions is not-empty, increment


with open("file.cpp", "r") as file:
    noCommentFile = removeComment(file.read())
    # print(noCommentFile)
    classOut = classIdentfication(noCommentFile)
    print("classes ",classOut)
    inheritClass = inheritedClass(noCommentFile)
    print("Inherited classes ",inheritClass)
    # print(CLASSNAME)
    objects=objectFun(noCommentFile)
    print("Objects Declaration ",objects)
    overloadedFunction(noCommentFile)


# r'class\s+([A-Za-z_]\w*)\s*\:\s*(public|private|protected)?\s+[A-Za-z_]\w*'
# r'([A-Za-z_]\w*)\:\:([A-Za-z_]\w*)\s*\(.*\)[^;]+|([A-Za-z_]\w*)\s*\(.*\)[^;]+'
# r'([A-Za-z_]\w*)\s*\*?\s+([A-Za-z_]\w*) | ([A-Za-z_]\w*)\s+\*?\s*([A-Za-z_]\w*)'