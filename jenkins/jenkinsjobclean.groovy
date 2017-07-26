import hudson.node_monitors.* 
import hudson.slaves.* 

hudson = Hudson.instance 

for (slave in hudson.slaves) { 
    try { 
        wsRoot = slave.getWorkspaceRoot() 
        space = DiskSpaceMonitor.DESCRIPTOR.get(slave.computer) 
        if (!wsRoot || !space) return 
        for (dir in wsRoot.list()) { 
            try { 
            item = hudson.getItem(dir.name) 
            if (item instanceof AbstractProject) { processProject(slave, item, dir) } 
          } catch (Exception e) { 
            println "    workspace: ${dir.name}, has no Hudson object, will delete" 
            processDeadDir(slave, dir) 
          } 
        } 
      } catch (InterruptedException ie) { 
        throw ie 
      } catch (Exception e) { 
        println "  ERR in slave processing: ${e}" 
      } 

def processProject(slave, proj, dir) { 
  try { 
    printWS(slave, proj, dir) 
    if (proj.getLastBuiltOn() != slave) { 
      age = new Date() - new Date(dir.lastModified()) 
      if (age > 180) { 
        println "    => deleting: ${dir} on ${slave.name}  " 
        tryDelete(slave, proj, dir) 
      } 
    } 
  } catch (InterruptedException ie) { 
    throw ie 
  } catch (Exception e) { 
    println "  ERR in processProject: ${e}" 
  } 
} 

def processDeadDir(slave, dir) { 
  try { 
    println "    => deleting: ${dir} on ${slave.name}  " 
    dir.deleteRecursive() 
  } catch (InterruptedException ie) { 
    throw ie 
  } catch (Exception e) { 
    println "  ERR in processDeadDir: ${e}" 
  } 
} 

def printWS(slave, proj, dir) { 
  try { 
      age = new Date() - new Date(dir.lastModified()) 
      lastBuiltOn = proj.getLastBuiltOn() 
      same = (lastBuiltOn == slave) 
      where = lastBuiltOn instanceof DumbSlave ? lastBuiltOn.name : lastBuiltOn 
      println "    workspace: ${dir.name}, age: ${age} days, last built on: ${where}, ${same ? 'keep' : 'could delete'}" 
  } catch (Exception e) { 
    println "  ERR in print: ${e}" 
  } 
} 

def tryDelete(slave, proj, dir) { 
  if (proj.scm.processWorkspaceBeforeDeletion(proj, dir, slave)) { 
    dir.deleteRecursive() 
  } 
} 
