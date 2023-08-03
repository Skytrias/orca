import xml.etree.ElementTree as et
from argparse import ArgumentParser
from datetime import datetime

#---------------------------------------------------------------
#NOTE: get args
#---------------------------------------------------------------

parser = ArgumentParser()
parser.add_argument("-s", "--spec")
parser.add_argument("-d", "--directory")

args = parser.parse_args()

apiName = 'gl_api'
loaderName = 'gl_loader'

apiPath = args.directory + '/' + apiName + '.h'
loaderHeaderPath = args.directory + '/' + loaderName + '.h'
loaderCPath = args.directory + '/' + loaderName + '.c'

#---------------------------------------------------------------
#NOTE: gather all GL functions in GL 4.1, 4.3, and GLES 3.0 and 3.1
#---------------------------------------------------------------

def gather_api(tree, api, version):
	procs = []
	for	feature in tree.iterfind('feature[@api="'+ api +'"]'):
		if float(feature.get('number')) > version:
			break

		for require in feature.iter('require'):
			if require.get('profile') == 'compatibility':
				continue
			for command in require.iter('command'):
				procs.append(command.get('name'))

		for remove in feature.iter('remove'):
			for command in remove.iter('command'):
				procs.remove(command.get('name'))
	return(procs)

tree = et.parse(args.spec)

# put all GL commands in a dict
commands = dict()
commandsSpec = tree.find('./commands')
for command in commandsSpec.iter('command'):
	name = command.find('proto/name')
	commands[name.text] = command

#gather command names per API
gl41 = gather_api(tree, 'gl', 4.1)
gl43 = gather_api(tree, 'gl', 4.3)
gl44 = gather_api(tree, 'gl', 4.4)
gles31 = gather_api(tree, 'gles2', 3.1)
gles32 = gather_api(tree, 'gles2', 3.2)

glall = list(set().union(gl41, gl43, gl44, gles31, gles32))


#---------------------------------------------------------------
# helpers
#---------------------------------------------------------------

def emit_doc(f, name, ext):
	f.write("/********************************************************\n")
	f.write("*\n")
	f.write("*\t@file: " + name + ext + '\n')
	f.write("*\t@note: auto-generated by glapi.py from gl.xml\n")
	f.write("*\t@date: %s\n" % datetime.now().strftime("%d/%m%Y"))
	f.write("*\n")
	f.write("*********************************************************/\n")


def emit_begin_guard(f, name):
	guard = '__' + name.upper() + '_H__'
	f.write("#ifndef " + guard + "\n")
	f.write("#define " + guard + "\n\n")

def emit_end_guard(f, name):
	guard = '__' + name.upper() + '_H__'
	f.write("#endif // " + guard + "\n")

def remove_prefix(s, prefix):
	if s.startswith(prefix):
		return s[len(prefix):]

#---------------------------------------------------------------
# Generate GL API header file
#---------------------------------------------------------------

f = open(apiPath, 'w')

emit_doc(f, apiName, '.h')
emit_begin_guard(f, apiName)

f.write('#include"GL/glcorearb.h"\n')
f.write('#include"GLES3/gl32.h"\n\n')

# generate interface struct
f.write('typedef struct mg_gl_api\n{\n')

f.write('	const char* name;\n')

for func in glall:
	f.write('\t' + 'PFN' + func.upper() + 'PROC ' + remove_prefix(func, 'gl') + ';\n')

f.write('} mg_gl_api;\n\n')

# generate interface macros
# TODO guard for different api/versions and only #define functions present in desired version
f.write("MP_API mg_gl_api* mg_gl_get_api(void);\n\n")

for func in glall:
	f.write('#define ' + func + ' mg_gl_get_api()->' + remove_prefix(func, 'gl') + '\n')

emit_end_guard(f, apiName)
f.close()

#---------------------------------------------------------------
# Generate GL loader header
#---------------------------------------------------------------

f = open(loaderHeaderPath, 'w')

emit_doc(f, loaderName, '.h')
emit_begin_guard(f, loaderName)

f.write('#include"gl_api.h"\n\n')

f.write("typedef void*(*mg_gl_load_proc)(const char* name);\n\n")

f.write("void mg_gl_load_gl41(mg_gl_api* api, mg_gl_load_proc loadProc);\n")
f.write("void mg_gl_load_gl43(mg_gl_api* api, mg_gl_load_proc loadProc);\n")
f.write("void mg_gl_load_gl44(mg_gl_api* api, mg_gl_load_proc loadProc);\n")
f.write("void mg_gl_load_gles30(mg_gl_api* api, mg_gl_load_proc loadProc);\n")
f.write("void mg_gl_load_gles31(mg_gl_api* api, mg_gl_load_proc loadProc);\n\n")

f.write("void mg_gl_select_api(mg_gl_api* api);\n\n")

emit_end_guard(f, loaderName)
f.close()
#---------------------------------------------------------------
# Generate GL loader code
#---------------------------------------------------------------

def emit_loader(f, name, procs):
	f.write('void mg_gl_load_'+ name +'(mg_gl_api* api, mg_gl_load_proc loadProc)\n')
	f.write("{\n")
	f.write('	api->name = "'+ name +'";\n')

	for proc in glall:
		if proc in procs:
			f.write('	api->' + remove_prefix(proc, 'gl') + ' = loadProc("' + proc + '");\n')
		else:
			f.write('	api->' + remove_prefix(proc, 'gl') + ' = mg_' + proc + '_noimpl;\n')

	f.write("}\n\n")


def emit_null_api(f, procs):

	f.write('mg_gl_api __mgGLNoAPI;\n\n')

	for name in procs:

		command = commands.get(name)
		if command == None:
			print("Couldn't find definition for required command '" + name + "'")
			exit(-1)

		proto = command.find("proto")
		ptype = proto.find("ptype")

		retType = ''
		if proto.text != None:
			retType += proto.text

		if ptype != None:
			if ptype.text != None:
				retType += ptype.text
			if ptype.tail != None:
				retType += ptype.tail

		retType = retType.strip()

		f.write(retType + ' mg_' + name + '_noimpl(')

		params = command.findall('param')
		for i, param in enumerate(params):

			argName = param.find('name').text

			typeNode = param.find('ptype')
			typeName = ''

			if param.text != None:
				typeName += param.text

			if typeNode != None:
				if typeNode.text != None:
					typeName += typeNode.text
				if typeNode.tail != None:
					typeName += typeNode.tail

			typeName = typeName.strip()

			f.write(typeName + ' ' + argName)

			if i < len(params)-1:
				f.write(', ')

		f.write(')\n')
		f.write('{\n')
		f.write('	if(__mgGLAPI == &__mgGLNoAPI)\n')
		f.write('	{\n')
		f.write('		log_error("No GL or GLES API is selected. Make sure you call mg_surface_prepare() before calling OpenGL API functions.\\n");\n')
		f.write('	}\n')
		f.write('	else\n')
		f.write('	{\n')
		f.write('		log_error("'+ name +' is not part of currently selected %s API\\n", __mgGLAPI->name);\n')
		f.write('	}\n')
		if retType != 'void':
			f.write('	return(('+ retType +')0);\n')
		f.write('}\n')

	f.write('mg_gl_api __mgGLNoAPI = {\n')
	for proc in procs:
		f.write('	.' + remove_prefix(proc, 'gl') + ' = mg_' + proc + '_noimpl,\n')
	f.write("};\n\n")

f = open(loaderCPath, 'w')

emit_doc(f, loaderName, '.c')

f.write('#include"' + loaderName + '.h"\n')
f.write('#include"platform.h"\n\n')

f.write("mp_thread_local mg_gl_api* __mgGLAPI = 0;\n")

emit_null_api(f, glall)
emit_loader(f, 'gl41', gl41)
emit_loader(f, 'gl43', gl43)
emit_loader(f, 'gl44', gl44)
emit_loader(f, 'gles31', gles31)
emit_loader(f, 'gles32', gles32)

f.write("void mg_gl_select_api(mg_gl_api* api){ __mgGLAPI = api; }\n")
f.write("void mg_gl_deselect_api(){ __mgGLAPI = &__mgGLNoAPI; }\n")
f.write("mg_gl_api* mg_gl_get_api(void) { return(__mgGLAPI); }\n\n")

f.close()
