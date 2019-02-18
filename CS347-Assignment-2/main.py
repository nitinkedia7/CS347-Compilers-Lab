import re


class CppParser:

    def __init__(self):
        self.num_of_class = 0
        self.num_of_inherited_class = 0
        self.num_of_constructors = 0
        self.num_of_operator_over = 0
        self.num_of_objects = 0

        self.class_names = list()
        self.inherited_class_names = list()
        self.constructor_types = list()
        self.operator_overload = list()
        self.object_names = {}

    def comment_removal(self, complete_text):
        def substituter(matching_text):
            string = matching_text.group(0)
            if string.startswith('/') or string.startswith('"'):
                return " "
            else:
                return string
        pattern = re.compile(r'"(\\.|[^\\"])*"|//.*?$|/\*.*?\*/', re.DOTALL | re.MULTILINE)
        no_comment_file = re.sub(pattern, substituter, complete_text)
        return no_comment_file

    def remove_alias(self, complete_text):
        def substituter(matching_text):
            string = matching_text.group(0)
            if string.startswith('#define'):
                return " "
            else:
                return string
        pattern = r'(#define .*?)[\n$]'
        defines = re.findall(pattern, complete_text)
        # print(defines)
        no_comment_file = re.sub(pattern, substituter, complete_text)
        new_file = no_comment_file
        for iter in defines:
            x = iter.split(' ')
            print(x)
            pat = r'\b'+x[1]+r'\b'
            repl = ' '.join(x[2:])
            new_file = re.sub(pat, repl, new_file)
        return new_file

    def find_classes(self, complete_text):
        text_lines = complete_text.split('\n')
        for line in text_lines:
            line = line + '\n'
            class_found_flag = False
            in_class_found_flag = False
            class_finder = r'\bclass\b\s+([A-Za-z_]\w*)\s*[\n\{]'
            class_names = re.findall(class_finder, line)
            inherited_class_finder = r'\bclass\b\s+([A-Za-z_]\w*)\s*\:\s*((?:public|private|protected)?\s+(?:[A-Za-z_]\w*)\s*\,?\s*)+[\n\{]'
            inherited_class_names = re.findall(inherited_class_finder, line)
            class_names = list(filter(None, class_names))
            if len(class_names) > 0:
                class_found_flag = True
            if len(inherited_class_names) > 0:
                in_class_found_flag = True
            if class_found_flag or in_class_found_flag:
                self.num_of_class = self.num_of_class + 1
            for class_name in class_names:
                if class_name not in self.class_names:
                    self.class_names.append(class_name)

    # class subclass_name : access_mode base_class_name
    def find_inherited_classes(self, complete_text):
        text_lines = complete_text.split('\n')
        for line in text_lines:
            line = line + '\n'
            inherited_class_finder = r'\bclass\b\s+([A-Za-z_]\w*)\s*\:\s*((?:public|private|protected)?\s+(?:[A-Za-z_]\w*)\s*\,?\s*)+[\n\{]'
            inherited_class_names = re.findall(inherited_class_finder, line)
            if len(inherited_class_names) > 0:
                self.num_of_inherited_class = self.num_of_inherited_class + 1

            for class_name in inherited_class_names:
                if class_name not in self.inherited_class_names:
                    self.inherited_class_names.append(class_name)
                    self.class_names.append(class_name[0])


    # MyClass::MyClass() { }
    # MyClass(T x) { xxx = x; }
    # MyClass(double r = 1.0, string c = "red") : radius(r), color(c) { }
    def find_constructors(self, complete_text):
        text_lines = complete_text.split('\n')
        for line in text_lines:
            line = line + '\n'
            constructors_finder = r'(?:[^~]|^)\b([A-Za-z_][\w\:\s]*)\s*\(([^)]*?)\)?\s*[\n\{\:]'          
            constructors_list = re.findall(constructors_finder, line)
            constructor_found = False
            for definition in constructors_list:
                belonging_class = definition[0].split('::')
                length = len(belonging_class)
                belonging_class = [x.strip() for x in belonging_class]
                if belonging_class[-1] in self.class_names:
                    if length == 1:
                        constructor_found = True
                        self.constructor_types.append(definition)
                    elif belonging_class[-1] == belonging_class[-2]:
                        constructor_found = True
                        self.constructor_types.append(definition)
            if constructor_found:
                self.num_of_constructors = self.num_of_constructors + 1

    # returnType operator symbol (arguments){}
    def find_overloaded_operators(self, complete_text):
        text_lines = complete_text.split('\n')
        for line in text_lines:
            line = line + '\n'
            operators = r'(\+=|-=|\*=|/=|%=|\^=|&=|\|=|<<|>>|>>=|<<=|==|!=|<=|>=|<=>|&&|\|\||\+\+|--|\,|->\*|\\->|\(\s*\)|\[\s*\]|\+|-|\*|/|%|\^|&|\||~|!|=|<|>)'
            overloaded_operators_finder = r'\boperator\b\s*' + operators + r'\s*([^\{\;]*)?[\n\{]'         
            overloaded_operators = re.findall(overloaded_operators_finder, line)
            if len(overloaded_operators) > 0:
                self.num_of_operator_over = self.num_of_operator_over + 1
            for operator in overloaded_operators:
                self.operator_overload.append(operator)

    def find_objects_declaration(self, complete_text):
        text_lines = complete_text.split('\n')
        for line in text_lines:
            line = line + '\n'
            objects_finder = r'([A-Za-z_]\w*)\b\s*([\s\*]*[A-Za-z_\,][A-Za-z0-9_\.\,\[\]\s\(\)]*[^\n<>]*?);'
            class_object_list = re.findall(objects_finder, line)
            object_found = False
            for objects in class_object_list:
                if objects[0] in self.class_names:
                    if objects[0] not in self.object_names:
                        self.object_names[objects[0]] = ''
                    self.object_names[objects[0]] += (objects[1]+',')
                    object_found = True
            if object_found:
                self.num_of_objects = self.num_of_objects + 1

    def load_file_and_parse(self, file_name):
        file_name = 'input/' + file_name
        try:
            with open(file_name, 'r') as cpp_file:
                cleaned_file = self.comment_removal(cpp_file.read())
                cleaned_file = self.remove_alias(cleaned_file)
                self.find_classes(cleaned_file)
                self.find_inherited_classes(cleaned_file)
                self.find_constructors(cleaned_file)
                self.find_overloaded_operators(cleaned_file)
                self.find_objects_declaration(cleaned_file)
                self.print_statistics()
        except FileNotFoundError:
            print('File not found!')
            exit(1)

    def print_statistics(self):
        print('Classes              : ', self.num_of_class)
        print('Inherited classes    : ', self.num_of_inherited_class)
        print('Constructors         : ', self.num_of_constructors)
        print('Operator Overloading : ', self.num_of_operator_over)
        print('Objects Declaration  : ', self.num_of_objects)
        
    def print_class_stats(self):
        print('Classes : \n', self.class_names)

    def print_inherited_class_stats(self):
        print('Inherited Classes : \n', self.inherited_class_names)

    def print_constructor_stats(self):
        print('Constructors : ', )
        for constructor in self.constructor_types:
            print(constructor)

    def print_operator_overload_stats(self):
        print('Overloaded Operators : ')
        for operators in self.operator_overload:
            print(operators)

    def print_objects_stats(self):
        print('Objects : ')
        for objects in self.object_names:
            print(objects, ':', self.object_names[objects][:-1])


if __name__ == '__main__':
    class_instance = CppParser()
    user_file_name = input('Enter the file name (should be present in input/) : ')
    class_instance.load_file_and_parse(user_file_name)
    class_instance.print_class_stats()
    class_instance.print_inherited_class_stats()
    class_instance.print_constructor_stats()
    class_instance.print_operator_overload_stats()
    class_instance.print_objects_stats()
