USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE MCP SERVER HEALTHCARE_DB.GOLD.MULTI_MCP_SERVER
  FROM SPECIFICATION $$
    tools:
      - name: "HEALTHCARE_AGENT"
        type: "CORTEX_AGENT_RUN"
        identifier: "HEALTHCARE_DB.GOLD.HEALTHCARE_AGENT"
        title: "Healthcare Agent"
        description: "ONLY use for healthcare questions about patient admissions, insurance claims, treatment outcomes, hospital departments, and diagnoses. Do NOT use this tool for sales, revenue, or finance questions."

      - name: "FINANCE_AGENT"
        type: "CORTEX_AGENT_RUN"
        identifier: "SALES_DB.ANALYTICS.FINANCE_AGENT"
        title: "Finance Agent"
        description: "ONLY use for finance and sales questions about total sales amount, revenue by region, product categories, order status, and customers. Do NOT use this tool for healthcare, patients, or medical questions."
  $$;


SHOW MCP SERVERS IN SCHEMA HEALTHCARE_DB.GOLD;

---SHOW MCP SERVERS IN SCHEMA HEALTHCARE_DB.GOLD;


-- Grant READER_ROLE access to both agents across databases
-- the new combined server
GRANT USAGE ON MCP SERVER HEALTHCARE_DB.GOLD.MULTI_MCP_SERVER TO ROLE reader_role;

-- finance agent + its data
GRANT USAGE  ON AGENT SALES_DB.ANALYTICS.FINANCE_AGENT TO ROLE reader_role;
GRANT USAGE  ON DATABASE SALES_DB           TO ROLE reader_role;
GRANT USAGE  ON SCHEMA   SALES_DB.ANALYTICS TO ROLE reader_role;
GRANT SELECT ON SEMANTIC VIEW SALES_DB.ANALYTICS.FINANCE_SEMANTIC_VW TO ROLE reader_role;
GRANT SELECT ON ALL TABLES IN SCHEMA SALES_DB.ANALYTICS TO ROLE reader_role;
GRANT USAGE  ON WAREHOUSE SALES_WH TO ROLE reader_role;
-- (reader_role already has CORTEX_USER, HEALTHCARE_WH, and the healthcare grants)

SHOW GRANTS TO ROLE reader_role;


--   {
--   "servers": {
--     "healthcare_mcp_server": {
--       "type": "http",
--       "url": "https://HTTJFFR-BW29102.snowflakecomputing.com/api/v2/databases/HEALTHCARE_DB/schemas/GOLD/mcp------servers/healthcare_mcp_server",
--       "headers": { "Authorization": "Bearer <READER_ROLE_TOKEN>" }
--     },
--     "finance_mcp_server": {
--       "type": "http",
--       "url": "https://HTTJFFR-BW29102.snowflakecomputing.com/api/v2/databases/SALES_DB/schemas/ANALYTICS/mcp-servers/finance_mcp_server",
--       "headers": { "Authorization": "Bearer <FINANCE_ROLE_TOKEN>" }
--     }
--   }
-- };

---VS Code sees both servers, each with its own tools, and you can talk to both agents in the same chat session. The LLM picks the right -------tool based on your question.

SHOW GRANTS TO ROLE READER_ROLE;

---CALL SYSTEM$GENERATE_MCP_TOKEN('HEALTHCARE_DB.GOLD.MULTI_MCP_SERVER');