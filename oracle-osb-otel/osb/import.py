# WLST script that imports the config jar built by configjar into the running
# OSB domain. Run it with the wlst.sh wrapper in the configjar tool directory,
# because that wrapper puts the OSB classes on the WLST classpath. Plain
# wlst.sh from oracle_common cannot import com.bea.wli.sb.
#
# OSB changes are made inside a named session, which is then activated. If a
# previous run died part way through, its session is still open on the server
# and creating it again fails, so any stale session is discarded first.

from com.bea.wli.sb.management.configuration import SessionManagementMBean
from com.bea.wli.sb.management.configuration import ALSBConfigurationMBean
from java.io import File, FileInputStream
import jarray
import sys

JAR = "/tmp/osb-demo/sbconfig.jar"
ADMIN_URL = "t3://soaas:7001"
USERNAME = "weblogic"
PASSWORD = "welcome1"
SESSION = "osbDemoImport"

connect(USERNAME, PASSWORD, ADMIN_URL)
domainRuntime()

smb = findService(SessionManagementMBean.NAME, SessionManagementMBean.TYPE)
if smb.sessionExists(SESSION):
    print "Discarding stale session %s from an earlier run." % SESSION
    smb.discardSession(SESSION)
smb.createSession(SESSION)

cfg = findService("ALSBConfiguration." + SESSION, ALSBConfigurationMBean.TYPE)

jar = File(JAR)
stream = FileInputStream(jar)
contents = jarray.zeros(int(jar.length()), "b")
stream.read(contents)
stream.close()
cfg.uploadJarFile(contents)

plan = cfg.getImportJarInfo().getDefaultImportPlan()
plan.setPreserveExistingEnvValues(false)
result = cfg.importUploaded(plan)

if result.getFailed().isEmpty():
    smb.activateSession(SESSION, "Import DemoProject")
    print "Activated. Imported:"
    for ref in result.getImported():
        print "    %s" % ref
else:
    print "Import failed:"
    for entry in result.getFailed().entrySet():
        print "    %s -> %s" % (entry.getKey(), entry.getValue())
    smb.discardSession(SESSION)
    sys.exit(1)