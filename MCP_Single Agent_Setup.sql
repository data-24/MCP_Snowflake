/* =====================================================================
   HEALTHCARE CORTEX AGENT  ->  MCP  ->  VS CODE
   Full setup script, in order. Run top to bottom.
   Co-authored with CoCo.

   WHAT IS MCP
   - MCP = "USB-C for AI": one standard protocol, any client, any server.
   - Server (Snowflake) exposes capabilities as TOOLS (e.g. run this agent).
   - Client (VS Code, Claude, Cursor, ...) discovers and calls those tools.
   - The client never logs into Snowflake; only the answer travels.
   - Security: token (PAT) or OAuth 2.0 auth + Snowflake RBAC + audit logging.

   PLACEHOLDERS to replace with your own:
     Database  : HEALTHCARE_DB
     Schemas   : GOLD (semantic view/stage) , RAW (source tables)
     Agent     : HEALTHCARE_AGENT
     Warehouse : HEALTHCARE_WH
     Username  : ADMIN            (run: SELECT CURRENT_USER();)

   ORDER OF WORK
     PART A  Create the MCP server + set default warehouse   (ACCOUNTADMIN)
     PART B  Quick test with an ACCOUNTADMIN token           (proves pipeline)
     PART C  Create reader_role and grant least privilege
     PART D  Give the role to your user + verify
     PART E  Test reader_role directly in Snowsight
     PART F  Use it in VS Code (notes)
   ===================================================================== */


/* =====================================================================
   PART A -- Create the MCP server and set a default warehouse
   Run as ACCOUNTADMIN. Assumes HEALTHCARE_DB.GOLD.HEALTHCARE_AGENT exists.
   ===================================================================== */
USE ROLE ACCOUNTADMIN;


-- Default warehouse is set on the USER, so it applies to any role
-- (without it the agent fails: "You must specify the warehouse to use")
ALTER USER ADMIN SET DEFAULT_WAREHOUSE = 'HEALTHCARE_WH';


 -- Create a least-privileged role and grant what the agent needs
  
---USE ROLE ACCOUNTADMIN;
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE ROLE  reader_role;


-- 4) Containers -- database and schemas.
GRANT USAGE ON DATABASE HEALTHCARE_DB      TO ROLE reader_role;
GRANT USAGE ON SCHEMA   HEALTHCARE_DB.GOLD TO ROLE reader_role;
GRANT USAGE ON SCHEMA   HEALTHCARE_DB.RAW  TO ROLE reader_role;

-- 5) What the agent actually reads:
--    the semantic view (Cortex Analyst queries this) ...
GRANT SELECT ON SEMANTIC VIEW HEALTHCARE_DB.GOLD.HEALTHCARE_SEMANTIC_VW TO ROLE reader_role;
--    ... the underlying source tables ...
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_DB.RAW TO ROLE reader_role;
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_DB.GOLD TO ROLE reader_role;
--    ... and the stage the agent uses.
GRANT READ ON STAGE HEALTHCARE_DB.GOLD.SKILL_STAGE TO ROLE reader_role;

-- 6) Compute -- a warehouse to run the queries.
GRANT USAGE ON WAREHOUSE HEALTHCARE_WH TO ROLE reader_role;

-- 7) OPTIONAL -- only if your agent uses a Cortex Search service.
--    List first, then grant the real name (uncomment both lines):
-- SHOW CORTEX SEARCH SERVICES IN SCHEMA HEALTHCARE_DB.GOLD;
-- GRANT USAGE ON CORTEX SEARCH SERVICE HEALTHCARE_DB.GOLD.<paste_real_name> TO ROLE reader_role;


/* =====================================================================
   PART D -- Give the role to your user and verify everything
   ===================================================================== */
-- The role must be granted to whoever logs in, or it will not appear
-- in the "Generate token" dialog.
GRANT ROLE reader_role TO USER ADMIN;

-- Verify: you should see MCP_SERVER, AGENT, CORTEX_USER (database role),
-- DATABASE, SCHEMA (GOLD + RAW), SEMANTIC_VIEW, STAGE, WAREHOUSE.
SHOW GRANTS TO ROLE reader_role;

-- Expose the Cortex agent as an MCP tool
CREATE OR REPLACE MCP SERVER HEALTHCARE_DB.GOLD.healthcare_mcp_server
  FROM SPECIFICATION $$
  tools:
    - name: "HEALTHCARE_AGENT"
      type: "CORTEX_AGENT_RUN"
      identifier: "HEALTHCARE_DB.GOLD.HEALTHCARE_AGENT"
      description: "Healthcare operations intelligence agent for
                    patient admissions, insurance claims, and treatment outcomes."
  $$;

-- Confirm it exists (name is stored uppercase: HEALTHCARE_MCP_SERVER)
SHOW MCP SERVERS IN SCHEMA HEALTHCARE_DB.GOLD;


-- 1) The MCP server object -- lets the token reach the endpoint.
--    Missing -> VS Code: "MCP server does not exist or not authorized".
GRANT USAGE ON MCP SERVER HEALTHCARE_DB.GOLD.HEALTHCARE_MCP_SERVER TO ROLE reader_role;

-- 2) The agent -- lets the role invoke it.
GRANT USAGE ON AGENT HEALTHCARE_DB.GOLD.HEALTHCARE_AGENT TO ROLE reader_role;

-- 3) Cortex access -- REQUIRED for any non-admin role to run agents/analyst.
--    Missing -> "Error occurred while calling Data Agent / Unknown error".
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE reader_role;



SHOW GRANTS TO ROLE reader_role;


-- Revoke database/schema usage
REVOKE USAGE ON DATABASE HEALTHCARE_DB      FROM ROLE reader_role;
REVOKE USAGE ON SCHEMA   HEALTHCARE_DB.GOLD FROM ROLE reader_role;
REVOKE USAGE ON SCHEMA   HEALTHCARE_DB.RAW  FROM ROLE reader_role;

-- Revoke data access
REVOKE SELECT ON SEMANTIC VIEW HEALTHCARE_DB.GOLD.HEALTHCARE_SEMANTIC_VW FROM ROLE reader_role;
REVOKE SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_DB.RAW FROM ROLE reader_role;
REVOKE READ ON STAGE HEALTHCARE_DB.GOLD.SKILL_STAGE FROM ROLE reader_role;

-- Revoke compute
REVOKE USAGE ON WAREHOUSE HEALTHCARE_WH FROM ROLE reader_role;

-- Revoke role from user
REVOKE ROLE reader_role FROM USER ADMIN;

-- Revoke MCP server access
----REVOKE USAGE ON MCP SERVER HEALTHCARE_DB.GOLD.HEALTHCARE_MCP_SERVER FROM ROLE reader_role;

-- Revoke agent access
----REVOKE USAGE ON AGENT HEALTHCARE_DB.GOLD.HEALTHCARE_AGENT FROM ROLE reader_role;

-- Revoke Cortex access
----REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE reader_role;


-- Sanity checks
SHOW MCP SERVERS IN SCHEMA HEALTHCARE_DB.GOLD;
DESCRIBE MCP SERVER HEALTHCARE_DB.GOLD.HEALTHCARE_MCP_SERVER;
SHOW WAREHOUSES LIKE 'HEALTHCARE_WH';   -- STARTED or SUSPENDED are both fine


/* =====================================================================
   PART E -- Test reader_role directly in Snowsight (get the REAL error)
   MCP hides failures as "Unknown error"; Snowsight shows the real message.
   Switch to reader_role, then open HEALTHCARE_AGENT in Snowsight and ask
   a question. If it works here, it will work through MCP in VS Code.
   ===================================================================== */
USE ROLE reader_role;
USE WAREHOUSE HEALTHCARE_WH;
-- Now open HEALTHCARE_AGENT in Snowsight (while using reader_role) and ask:
--   "count insurance claims grouped by claim status"


/* =====================================================================
   PART F -- Use it in VS Code (notes, not SQL)
   ---------------------------------------------------------------------
   1) Generate a token scoped to reader_role:
        Snowsight -> your user -> Programmatic access tokens
        -> Generate new token -> Single role = READER_ROLE -> copy it.

   2) Create the file .vscode/mcp.json in your project (exact path/name):

      {
        "servers": {
          "healthcare_mcp_server": {
            "type": "http",
            "url": "https://<ORG>-<ACCOUNT>.snowflakecomputing.com/api/v2/databases/HEALTHCARE_DB/schemas/GOLD/mcp-servers/healthcare_mcp_server",
            "headers": {
              "Authorization": "Bearer PASTE_YOUR_TOKEN_HERE"
            }
          }
        }
      }

      - "type" must be "http".
      - Authorization must be exactly "Bearer <token>" (one space, no leading space).
      - Find <ORG>-<ACCOUNT>:  SELECT CURRENT_ORGANIZATION_NAME(), CURRENT_ACCOUNT_NAME();

   3) Trust the workspace if prompted (Restricted Mode -> Manage -> Trust).

   4) Whenever you change the token or mcp.json:
        Ctrl+Shift+P -> Developer: Reload Window
        Ctrl+Shift+P -> MCP: List Servers -> healthcare_mcp_server -> Start/Restart
        Look for: "Connection state: Running"  and  "Discovered 1 tools".

   5) Chat panel -> Agent mode -> ask, e.g.
        "Using the healthcare agent tool only, count insurance claims by claim status."
      Approve the tool call (Allow in this Session).

   TIP: add ".vscode/mcp.json" to .gitignore so your token is never committed.
   ===================================================================== */
   ------------GiTHUB MCP CONNECTOR---------

USE ROLE ACCOUNTADMIN;


USE ROLE ACCOUNTADMIN;
DESCRIBE EXTERNAL MCP SERVER HEALTHCARE_DB.GOLD.GITHUB;
USE ROLE ACCOUNTADMIN;

-- Grant access to the external MCP server
GRANT USAGE ON EXTERNAL MCP SERVER HEALTHCARE_DB.GOLD.GITHUB TO ROLE READER_ROLE;

-- Grant access to the underlying API integration (replace with actual name from Step 1)
GRANT USAGE ON INTEGRATION GITHUB_MCP_INTEGRATION_BAE193C9 TO ROLE READER_ROLE;
USE ROLE ACCOUNTADMIN;


SHOW INTEGRATIONS LIKE 'GITHUB%';

-- Grant access to the GitHub external MCP server
GRANT USAGE ON EXTERNAL MCP SERVER HEALTHCARE_DB.GOLD.GITHUB TO ROLE READER_ROLE;

-- Grant access to the underlying API integration
GRANT USAGE ON INTEGRATION GITHUB_MCP_INTEGRATION_BAE193C9 TO ROLE READER_ROLE;



REVOKE USAGE ON INTEGRATION GITHUB_MCP_INTEGRATION_BAE193C9 FROM ROLE READER_ROLE;
REVOKE USAGE ON EXTERNAL MCP SERVER HEALTHCARE_DB.GOLD.GITHUB FROM ROLE READER_ROLE;


SHOW GRANTS TO ROLE READER_ROLE;