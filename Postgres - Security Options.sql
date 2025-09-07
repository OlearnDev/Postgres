	Security Options

+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
Chap.1 : PG_AUDIT in PostgreSQL
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


What is PgAudit?
-----------------
PgAudit (the PostgreSQL Audit Extension) is an open-source extension that provides detailed session and object 
audit logging for PostgreSQL databases. Its primary purpose is to generate highly granular log records of all 
database activity, which is essential for:

	Security & Compliance: Meeting regulatory requirements like GDPR, HIPAA, SOX, PCI-DSS, which mandate 
	detailed tracking of who did what and when.
	Forensic Analysis: Investigating security incidents or data breaches by providing a precise audit trail.
	Accountability: Monitoring user behavior and ensuring users are only performing authorized actions.

Without PgAudit, PostgreSQL''s native logging can tell you that a statement was run, but it struggles to 
provide a clear, user-friendly audit trail that answers questions like:

	"Who viewed this specific patient's record?"
	"Which user deleted this critical financial table?"
	"What data did this account change between 2:00 PM and 3:00 PM?"

How PgAudit Works: Core Concepts
--------------------------------
PgAudit works by intercepting commands as they are executed and generating log output that is then written to 
PostgreSQL''s standard log files (e.g., postgresql.log). It operates in two main modes:

	1. Session Auditing
	---------------------
	This mode logs all statements executed by a database session. You enable it for a user, database, or 
	system-wide.

	What it logs: Every SELECT, INSERT, UPDATE, DELETE, DDL (e.g., CREATE, ALTER), and other commands run in 
	the session.

	Use Case: Best for tracing all actions of a specific user or from a specific application.

	2. Object Auditing
	---------------------
	This mode is more granular. It logs only statements that affect a specific database object (e.g., a 
	particular table).

	What it logs: Only commands that touch the object you''ve specified for auditing (e.g., all SELECT and 
	INSERT operations on users table).

	Use Case: Best for protecting highly sensitive data (e.g., a salary or passwords table), where you need a focused audit trail without log noise from other activities.

Key Features and Output
-----------------------
PgAudit enhances the standard log output with structured, easy-to-parse information. A key feature is that it 
logs both the top-level statement and the details of each individual operation it triggers.

	Example Log Output:
	----------------------
	Imagine a user runs this SQL:

	UPDATE accounts SET balance = balance - 100 WHERE customer_id = 456;
	
	A standard PostgreSQL log might just show the UPDATE statement. With PgAudit enabled, the log would contain 
	entries like this:


AUDIT: SESSION,1,1,WRITE,UPDATE,,,UPDATE accounts SET balance = balance - 100 WHERE customer_id = 456;,<not logged>
AUDIT: SESSION,1,1,WRITE,UPDATE,accounts,public,UPDATE accounts SET balance = balance - 100 WHERE customer_id = 456;,<not logged>

Let''s break down the log format (SESSION,1,1,WRITE,UPDATE,accounts,public,...):

	- AUDIT: Identifies this as a PgAudit log entry.
	- SESSION: The audit type (could be OBJECT).
	- 1,1: A unique statement and substatement ID, linking the high-level command to its individual actions.
	- WRITE: The class of operation (READ, WRITE, DDL, ROLE, etc.).
	- UPDATE: The specific command verb.
	- accounts, public: The object (table) name and its schema.
	- The final part is the full statement text (which can be redacted for security if needed).

This structure allows you to easily trace that the UPDATE statement was executed and see exactly what object it 
affected.

How to Implement and Use PgAudit
---------------------------------
Using PgAudit involves a few key steps:

1. Installation
-------------------
PgAudit is included with many popular PostgreSQL distributions (like EDB''s Postgres Advanced Server, or the 
PGDG repositories). You need to add it to the shared_preload_libraries in your postgresql.conf file and restart
the server.

	# In postgresql.conf
	
	shared_preload_libraries = 'pgaudit'

2. Enabling Logging
-------------------
You can enable PgAudit at various levels using the pgaudit.log setting. This is typically set in postgresql.conf
or for specific users/databases via ALTER ROLE or ALTER DATABASE.

Examples:
---------

	To log all READ (SELECT) and WRITE (INSERT, UPDATE, DELETE) operations for all sessions:

		pgaudit.log = 'read, write'

	To log all DDL (Data Definition Language) statements (e.g., CREATE, ALTER):

		pgaudit.log = 'ddl'
		
	To log everything (very verbose, use with caution):

		pgaudit.log = 'all'
	
3. Enabling Object Auditing (More Granular)
---------------------------------------------
Use the pgaudit.role setting. You first create a role dedicated to audit policy, and then grant that role to 
the users you want to audit.

	-- 1. Create a role for audit policies
	CREATE ROLE auditor;

	-- 2. Set the pgaudit role setting (usually in postgresql.conf or per-database)
	SET pgaudit.role = 'auditor';

	-- 3. Grant this role to a user you want to audit
	GRANT auditor TO sus_user;

	-- 4. Now, set specific object policies using GRANT
	-- This will audit all SELECTs on the 'users' table
	GRANT SELECT ON users TO auditor;
	
Summary
-----------
	Aspect			Description
	What it is		A PostgreSQL extension for detailed, compliant audit logging.
	Primary Use		Security, compliance (GDPR, HIPAA, PCI-DSS), and forensic analysis.
	How it Works	Intercepts commands and writes structured, granular audit entries to the PostgreSQL server 
					log.
	Two Modes		Session Auditing: Logs all statements in a session. Object Auditing: Logs actions on 
					specific tables.
	Key Benefit		Provides a clear, unambiguous audit trail that links users to their actions on specific data
					objects.
	In essence, 	PgAudit transforms PostgreSQL''s general-purpose logging into a powerful, enterprise-grade 
					auditing system, making it possible to answer critical questions about database access and 
					changes with confidence.