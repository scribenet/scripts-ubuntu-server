#! /usr/bin/env python2
##
## Handle converting mysql complete mysql database to different encoding type
##
## Author    : Rob Frawley 2ND <rfrawley@scribenet.com>
## Copyright : (c) 2014 Scribe Inc.
## License   : MIT License <http://scr.mit-license.org/>
##

from sys import argv
import MySQLdb

# check for the required passwd paramiters
if len(argv) < 3:
    print "Usage: %s <db_user> <db_name> [db_host] [character_set=utf8mb4 collate_set=utf8mb4_general_ci]" % argv[0]
    exit(1)
else:
    db_user = argv[1]
    db_name = argv[2]

# check for the first optional peramiter
if len(argv) > 3:
    db_host = argv[3]
else:
    db_host = "localhost"

# check for the final two required paramiters
if len(argv) == 6:
    db_character_set = argv[4]
    db_collate_set = argv[5]
else:
    db_character_set = "utf8mb4"
    db_collate_set = "utf8mb4_general_ci"

# output some info about this script
print "MySQL Character/Collate Conversion"
print "By Rob Frawley 2nd <rfrawley@scribenet.com>"
print "Copyright 2014 Scribe Inc"
print "Licensed under the MIT License <http://scr.mit-license.org/>"
print ""

# get the db password
db_pass = raw_input("Please enter the DB password: ")

# output out configuration
print ""
print "Configuration:"
print "  db_user          : %s" % db_user
print "  db_name          : %s" % db_name
print "  db_host          : %s" % db_host
print "  db_pass          : ****"
print "  db_character_set : %s" % db_character_set
print "  db_collate_set   : %s" % db_collate_set
print ""

# continue?
tmp_go = raw_input("Would you like to continue? [y/n]: ")

if tmp_go != 'y' and tmp_go != 'Y':
    print "Bye!"
    exit(1)

# connect to mysql and get db pointer
db = MySQLdb.connect(host=db_host, user=db_user, passwd=db_pass, db=db_name)
cursor = db.cursor()

# alter database
print('Altering database "%s"...' % db_name),
cursor.execute("ALTER DATABASE `%s` CHARACTER SET '%s' COLLATE '%s'" % (db_name, db_character_set, db_collate_set))
print('done.')

# get all the tables
print('Getting table list from "%s"...' % db_name),
sql = "SELECT DISTINCT(table_name) FROM information_schema.columns WHERE table_schema = '%s'" % db_name
cursor.execute(sql)
results = cursor.fetchall()
print('done.')

# alter each table
for row in results:
    print '  Altering table "%s"' % row[0],
    sql = "ALTER TABLE `%s` convert to character set DEFAULT COLLATE DEFAULT" % (row[0])
    cursor.execute(sql)
    print "done."
db.close()

# complete
print ""
print "Conversion operations complete!"
