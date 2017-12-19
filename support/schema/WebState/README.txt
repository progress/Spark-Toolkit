WebState is a collection of SAMPLE tables that may or may not be used within
PMFO. By default the framework will operate 100% without use of a connected
database and certainly without use of tables within this database. Though
for advanced features and to illustrate principals of operation beyond the
default behavior, use of this dedicated database is suggested by reasoning:

1) It is a self-contained database which contains tables that have been
historically useful to other projects, and added based on real-world use.

2) It exists as a separate database so that it does not interfere with a
client's existing databases, as it may only apply to a modernized app.

3) Many of the tables defined contain transient or session-limited data that
does not need to be persisted via backups or replication, and is therefore
easier to contain within a separate database.

4) However, the tables MAY be merged into an existing database, but only if
the necessary schema areas are present in the target database, or the .df
file is modified to utilize the proper area names of the targe database.


Available Tables:
  WebAgentControl      - WebSpeed Batch processing, list of agents handling batch jobs
  WebAuditLog          - Generic auditing table, used for logging application events
  WebBatchJobHeader    - WebSpeed Batch processing, holds batch job description
  WebBatchJobHistory   - WebSpeed Batch processing, lists history of run jobs
  WebBatchJobParameter - WebSpeed Batch processing, holds parameters for job
  WebBatchJobQueue     - WebSpeed Batch processing, holds queue of jobs
  WebContext           - View-specific name/value pairs, associated with an identity
  WebDataStore         - Contains a named CLOB object, associated with a session
  WebFileStore         - Contains a file as a LOB, associated with a username
  WebHelp              - View-specific help text for on-screen objects
  WebLookup            - Simple name/value pairs used within the application
  WebMenu              - Generic table for producing an application menu structure
  WebMenuTranslate     - Pre-translated titles for available menu items
  WebProfile           - Standard user profile table for use with OERealm security
  WebRole              - List of roles available to the application
  WebRoleProfile       - Association of roles to a specific user profile
  WebRoleTask          - Association of tasks to a specific role
  WebSearch            - Generic token table with a word index for site searches
  WebSemaphore         - Obsolete table used by WebSpeed to elect a lead agent
  WebSession           - Contains information about a session
  WebSessionAttribute  - Provide storage to a name/value pair for a session
  WebSessionStat       - Track information about API requests/responses
  WebSetting           - Categorized name/value pairs used as application switches
  WebTask              - List of tasks available to the application
  WebTranslate         - Pre-translated pieces of text
