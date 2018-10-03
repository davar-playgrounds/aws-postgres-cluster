#!/usr/bin/python
"""
    This python script work as an ansible module.
    It writes a log file based on the input.
    This module is very specific for this playbook.
    Probably it will not work in other playbook without changes.
"""

__author__ = "Dyego Eugenio"
__copyright__ = "Copyleft with your own risk"
__credits__ = ["Dyego Eugenio"]
__license__ = "GPL"
__version__ = "1.0.0"
__maintainer__ = "Dyego Eugenio"
__email__ = "dyegoe@gmail.com"
__status__ = "Production"


DOCUMENTATION = '''
---
module: write_test_logs
short_description: Write log files
author: Dyego Eugenio
email: dyegoe@gmail.com
'''

EXAMPLES = '''
- name: "Write log file"
  write_test_logs:
        description: a short description of the test
        log_dir: /any/absolut/path/to/save/your/logs
        log_file: tests.log
        input: any_registered_var_from_previous_command
        type: database | docker | uri
        
'''

from ansible.module_utils.basic import AnsibleModule
import time, os.path
from traceback import format_exc


class WriteTestsLogs:
    def __init__(self):
        fields = {
            "description": {"required": True, "type": "str"},
            "log_dir": {"required": True, "type": "str"},
            "log_file": {"required": True, "type": "str"},
            "input": {"required": True, "type": "dict"},
            "host": {"required": True, "type": "str"},
            "type": {
                "required": True,
                "choices": ['database', 'docker', 'uri'],
                "type": 'str'
            },
        }
        self.module = AnsibleModule(argument_spec=fields)
        self._description = self.module.params['description']
        self._log_dir = self.module.params['log_dir']
        self._log_file = self.module.params['log_file']
        self._input = self.module.params['input']
        self._host = self.module.params['host']
        self._lines = []

    def main(self):
        choice_map = {
            "database": self._log_database,
            "docker": self._log_docker,
            "uri": self._log_uri
        }
        self._lines.append("Hostname: {0}".format(self._host))
        self._lines.append("Description: {0}".format(self._description))
        has_changed, result = choice_map.get(self.module.params['type'])()
        self.module.exit_json(changed=has_changed, meta=result)

    def _log_database(self):
        _changed = False
        self._lines.append("CMD: {0}".format(self._input['cmd']))
        if not self._input['stderr'] == "":
            self._lines.append("Output: {0}".format(self._input['stderr']))
        if not self._input['stdout'] == "":
            self._lines.append("Output: {0}".format(self._input['stdout']))
        self._write_file()
        return _changed, self._lines

    def _log_docker(self):
        _changed = False
        self._lines.append("CMD: {0}".format(self._input['cmd']))
        if not self._input['stderr'] == "":
            self._lines.append("Output: {0}".format(self._input['stderr']))
        if not self._input['stdout'] == "":
            self._lines.append("Output: {0}".format(self._input['stdout']))
        self._write_file()
        return _changed, self._lines

    def _log_uri(self):
        _changed = False
        if 'results' in self._input:
            for _item in self._input['results']:
                self._lines.append("URL: {0}".format(_item['url']))
                self._lines.append("Msg: {0}".format(_item['msg']))
                if 'content' in _item:
                    if not _item['content'] == "":
                        self._lines.append("Content: {0}".format(_item['content'].rstrip()))
        else:
            self._lines.append("URL: {0}".format(self._input['url']))
            self._lines.append("Output: {0}".format(self._input['msg']))
            if 'content' in self._input:
                if not self._input['content'] == "":
                    self._lines.append("Content: {0}".format(self._input['content'].rstrip()))

        self._write_file()
        return _changed, self._lines

    def _write_file(self):
        try:
            if not os.path.exists(self._log_dir):
                os.makedirs(self._log_dir)
            if not os.access(self._log_dir, os.W_OK):
                self.module.fail_json(msg="Source {0} not writable".format(self._log_dir))
        except Exception as _w_exc:
            self.module.fail_json(msg=str(_w_exc), exc=format_exc())
        try:
            with open("{0}{1}".format(self._log_dir, self._log_file), "a+") as _log:
                for _line in self._lines:
                    ts = time.gmtime()
                    _log.write("[{0}] {1}\n".format(
                        time.strftime("%Y-%m-%d %H:%M:%S", ts),
                        _line)
                    )
                _log.write("---------------------------------------------------------------------------------------\n")
                return True
        except Exception as _w_exc:
            self.module.fail_json(msg=str(_w_exc), exc=format_exc())
            return False


if __name__ == '__main__':
    write_test_logs = WriteTestsLogs()
    write_test_logs.main()
