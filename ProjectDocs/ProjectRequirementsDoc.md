# **WRight Now PRD**

## **1\. Executive Summary**

### **1.1 Product Vision**

To build the fastest, simplest, and most intuitive internal knowledge base for modern teams. "WRight Now" is the antidote to the slow, clunky, and over-complex tools that teams are forced to use. Our vision is to create a product so fast and simple that it feels invisible, allowing teams to get back to doing their actual work instead of fighting their software.

**Our Core Value Proposition:** "All your team's knowledge, instantly searchable. No setup required."

### **1.2 The Opportunity**

Extensive market research shows that the multi-billion dollar internal documentation market is dominated by two flawed incumbents:

1. **Confluence (The "Clunky Incumbent"):** Users universally complain about its "clunky" and "outdated" editor, "useless" search functionality that relies on exact keywords, and "exorbitant" pricing that locks them in.  
2. **Notion (The "Slow Power-Tool"):** Users are drawn to its modern feel but are ultimately frustrated by "slow performance," "overwhelming" complexity (databases, relations), and a "significant learning curve" just to perform simple tasks.

The market is ripe for a solution that **rejects complexity** and focuses **obsessively on speed, security, and usability**.

### **1.3 The Solution**

"WRight Now" is a feature-light, performance-heavy SaaS platform. We are not building a "better Notion." We are building a "worse Notion" that is infinitely faster at the one thing that matters: creating and retrieving knowledge.

Our differentiation is built on four pillars:

1. **AI Command Bar (RAG Search):** A sub-100ms, Cmd/Ctrl+K bar that uses Retrieval-Augmented Generation (RAG) to provide direct answers, not just search links.  
2. **The "No-Blocks" Editor:** A clean, lightweight, Google Docs-style collaborative editor that is fast, reliable, and free of the lag and complexity of the "block" paradigm.  
3. **Permissions-First Security:** A zero-trust architecture where all data is inaccessible by default, with granular controls at the user, team, and Org level.  
4. **Simple, "Boring" Hierarchy:** An intuitive folder-based navigation (Spaces \> Folders \> Documents) that requires zero setup or training, **powered by AI suggestions.**

All of this is built on a **100% FOSS (Free and Open-Source Software) backend**, ensuring data privacy, cost control, and zero vendor lock-in for our users.

### **1.4 Target Audience**

* **Primary (Initial GTM):** Teams (10-50 employees) who are "graduating" from Google Docs/unstructured notes but are terrified of Confluence's complexity and frustrated by Notion's lag.  
* **Secondary (Scale):** SMBs (50-500 employees) who are actively looking for a Confluence alternative that is fast, affordable, and secure.  
* **FOSS Community:** Technical teams that value the ability to self-host, inspect the code, and gain absolute control over their data.

### **1.5 User Personas**

* **Sarah, the Team Lead (SMB):** Needs a single source of truth for her 30-person team. She is non-technical. She needs to onboard new hires and share company policies. She is frustrated by how long it takes to find anything in her current system.  
* **David, the Developer:** Needs to find API documentation and internal code standards *now*. He values speed above all else and hates waiting for Confluence to load or for its search to fail.  
* **Alex, the Non-Technical User (HR/Ops):** Needs to create a beautiful, simple onboarding guide. Is intimidated by Confluence's macros and Notion's "database relations."  
* **Chris, the IT/Security Admin:** Needs to manage user access and prevent data leaks. Worries about insecure SaaS tools. Loves that WRight Now is FOSS, "permissions-first," and can be self-hosted.

### **1.6 Scope**

The scope of this design is the Minimum Viable Product (MVP) of WRight Now, which includes:

* A "permissions-first" architecture for granular access control.  
* An AI-powered (RAG) search and command bar.  
* A real-time collaborative text editor.  
* User Mentions (@) and Bi-Directional Linking.  
* **AI-powered Auto-Tagging and Folder Suggestions.**  
* A 100% Free and Open-Source Software (FOSS) backend.  
* Cross-platform clients for Web, Desktop (Mac/Windows/Linux), and Mobile (iOS/Android) with offline support.

### **1.7 Objectives**

* **Objective 1:** Build the "command center" for company knowledge, replacing Cmd+F (Find) with Cmd+K (Answer).  
* **Objective 2:** Ensure zero-trust security by building a "permissions-first" system where all data is inaccessible by default.  
* **Objective 3:** Control costs and ensure data privacy for our users by building on a 100% FOSS stack, with no vendor lock-in.  
* **Objective 4:** Deliver a user experience that is 10x faster and more reliable than the incumbents.

### 

### **1.8 Assumptions & Dependencies**

* **Assumption:** The target market (SMBs 50-500 employees) is willing to self-host or pay for a hosted version of a FOSS product to gain security and cost benefits.  
* **Assumption:** Modern open-source LLMs (e.g., Llama 3 8B) are "good enough" for high-quality RAG on technical documentation.  
* **Dependency:** The entire architecture relies on a stable, self-hosted PostgreSQL instance with the pg\_vector extension.  
* **Dependency:** The real-time collaboration relies on the Yjs CRDT library.

## 

## **2\. The 10-Step Launch Playbook**

1. **Step 1: Pick an Idea That's Done Before.**  
   * **Action:** Complete. We have selected the multi-billion dollar internal documentation market.  
2. **Step 2: Decide on a "Good Enough" MVP.**  
   * **Action:** Our V1.0 MVP is defined by this PRD. It is a "perfect" simple, fast, and secure wiki.  
   * **MVP Scope:** All Epics defined in Section 3 (RAG Search, Editor, Permissions, Team Management, Mentions & Notifications, Bi-Directional Linking, **AI Auto-Tagging & Folder Suggestions**) and Cross-Platform clients (Section 4).  
3. **Step 3: Offer a Lifetime Deal (LTD).**  
   * **Action:** We will launch a "Founder's" LTD for the *hosted cloud version* of WRight Now for **$99**.  
   * **Limits:** 5 users, 10GB storage, 1 workspace. This builds our initial hosted user base.  
4. **Step 4: Never Give Away an Account for Free.**  
   * **Action:** During the launch phase, the *hosted version* will have no free trial. The only way in is the paid LTD. The FOSS version remains free for self-hosters, which builds a separate community.  
5. **Step 5: Sell a Private LTD.**  
   * **Action:** Aggressively market the *hosted LTD* in targeted communities:  
     * **Reddit:** r/sysadmin, r/Productivity, r/saas, r/selfhosted (for those who prefer not to).  
     * **Facebook:** Groups for SMB owners, startup founders.  
     * **X (Twitter):** Targeting users complaining about Confluence/Notion.  
     * **FOSS Communities:** Hacker News, product-specific forums.  
6. **Step 6: Start Writing Content.**  
   * **Action:** Start content marketing *today*.  
   * **Topics:** "Why is Confluence Search So Bad?", "Notion is Too Slow," "The Best Open-Source Confluence Alternative," "WRight Now vs. Confluence: A Feature-by-Feature Takedown."  
7. **Step 7: Launch on AppSumo.**  
   * **Action:** After the private LTD, partner with AppSumo for a 2-week "Select" launch of our *hosted version*.  
   * **Goal:** Generate $100k+ in capital and acquire 5,000+ users.  
8. **Step 8: Do One Last Private LTD.**  
   * **Action:** Run a 72-hour "Last Chance Ever" LTD for the *hosted version* on our main site. After this, we switch to MRR-only for hosted.  
9. **Step 9: Get Honest Reviews.**  
   * **Action:** Funnel our 5,000+ happy LTD users into "ambassadors." Ask for reviews on G2, Capterra, and TrustPilot.  
10. **Step 10: Answer Questions in Communities.**  
    * **Action:** This becomes our long-term growth loop, with two prongs:  
      * **Hosted:** Answer "Confluence alternative" with a link to our cloud product.  
      * **FOSS:** Answer "self-hosted wiki" with a link to our GitHub repo.

## 

## **3\. Core Product & Feature Requirements**

### **3.1 Guiding Principles**

* **Speed is a Feature:** Every interaction, from app load to search, must be instant.  
* **Security by Default:** All features must go through the permissions filter. No exceptions.  
* **Simplicity Over "Power":** If a feature introduces complexity, it's rejected.  
* **FOSS & Interoperability:** Build on open standards (Postgres, Yjs) and avoid vendor lock-in.  
* **Clarity:** The user should never feel lost or "need training."

### 

### **3.2 Epic 1: The AI Command Bar (RAG Search)**

This is the \#1 core feature, replacing Cmd+F (Find) with Cmd+K (Answer).

* **FR 1.1: Global Access:** The user can trigger the search modal from *anywhere* in the app (web/desktop) using the global hotkey Cmd+K (macOS) or Ctrl+K (Win/Linux).  
* **FR 1.2: Instantaneous Modal:** The search modal itself must render in \< 50ms.  
* **FR 1.3: Natural Language Query:** Must accept natural language queries (e.g., "What is our vacation policy?").  
* **FR 1.4: RAG-Synthesized Answer:** Must return a direct, AI-synthesized answer at the top, followed by a list of source documents.  
* **FR 1.5: Permissions-First (CRITICAL):** All search results AND synthesized answers must be strictly filtered by the user's permissions. The RAG context must *only* be built from docs the user has Read access to.

Visualization: The AI Command Bar Experience  
A user hits Cmd+K.  
\+-------------------------------------------------+  
|                                                 |  
|  \[Search\] What is our vacation policy?          |  
|                                                 |  
|  ANSWER                                         |  
|  Our company offers 20 days of paid vacation... |  
|                                                 |  
|  SOURCES                                        |  
|  \[doc\] PTO & Vacation Guide (HR)                |  
|  \[doc\] Employee Handbook 2025 (HR)              |  
|                                                 |  
|  RESULTS                                        |  
|  \[doc\] Holiday Schedule (HR)                    |  
|        ...company \*\*vacation\*\* schedule...      |  
|                                                 |  
\+-------------------------------------------------+

### 

### **3.3 Epic 2: The "No-Blocks" Editor**

A lightweight, collaborative editor that feels like a modern Google Doc.

* **FR 2.1: Real-time Collaboration:** Multiple users can edit the same document simultaneously, with multi-colored cursors and avatars visible. (via Yjs)  
* **FR 2.2: "Slash" Command Menu (Formatting):** The user can type / to bring up a *simple* command menu.  
  * **MVP Menu:** H1, H2, H3, Bulleted List, Numbered List, Checkbox, Table, Image, Code Snippet, Quote, Divider.  
  * **What's NOT included:** Databases, Kanban boards, linked documents, etc.  
* **FR 2.3: "Slash" Command Menu (AI-Assist):** The / menu will also include AI actions (e.g., /summarize, /explain, /fix-spelling, /translate).  
* **FR 2.4: Rich Text:** Standard bold, italic, underline, strikethrough, and link.  
* **FR 2.5: Code Snippets:** A dedicated code block with syntax highlighting.  
* **FR 2.6: Image Handling:** Drag-and-drop image uploads.  
* **FR 2.7: Auto-Save:** Every change is saved instantly to the database.  
* **FR 2.8: Mentions:** Users can type @ to bring up an auto-complete menu to tag a User (@David Smith) or a Team (@Engineering). This action triggers a notification (see Epic 6).  
* **FR 2.9: Internal Doc Linking:** Users can type \[\[ to bring up an auto-complete menu to link to another document (e.g., \[\[API Guide\]\]). This creates a bi-directional link (see Epic 7).  
* **FR 2.10: AI Auto-Tagging (Background Process) (NEW):**  
  * As a document is saved, the RAG AI service will asynchronously analyze its content.  
  * The service will generate a list of 5-10 keyword tags (e.g., 'vacation', 'pto', 'policy', 'hr') relevant to the content.  
  * These tags will be stored *only in the search index* (not user-visible in the MVP UI) to dramatically improve search relevance for both RAG and keyword queries.

### 

### **3.4 Epic 3: The "Boring" Hierarchy**

The navigation must be instantly understandable.

* **FR 3.1: Spaces:** The top-level containers (e.g., "Engineering," "Marketing," "HR").  
* **FR 3.2: Folders:** Inside Spaces, users can create nested folders.  
* **FR 3.3: Documents:** The individual pages (created with the Editor) live inside folders.  
* **FR 3.4: Drag-and-Drop:** Users can re-organize docs and folders by dragging them in the sidebar.  
* **FR 3.5: AI Folder Suggestions (NEW):**  
  * When a user creates a new document (or clicks 'Move' on an existing doc), the AI will analyze its content.  
  * A "Smart Suggestions" list will appear in the move/save modal, recommending the top 3 most relevant Spaces/Folders.  
  * This helps prevent document disorganization and fits the "no-setup" guiding principle.

**Visualization: The Main UI & Editor (Updated)**

\+------------------+---------------------------------------------------+  
| \[Workspace Name\] | \[doc\] Engineering Onboarding Guide   \[Share\] \[User\] |  
|------------------|---------------------------------------------------|  
| \[Cmd+K Search\]   |                                                   |  
| \[Inbox\]          |  \<h1\>Engineering Onboarding Guide\</h1\>             |  
|                  |                                                   |  
| \[Spaces\]         |  Welcome to the team\! Hey @Engineering, please... |  
| \> Engineering    |  ...check the \[\[API Guide\]\] for more info.         |  
|   \> API Docs     |                                                   |  
|   \> Guides       |  /                                                 |  
|     \- Onboarding |  \+-------------------+                           |  
|     \- Deploy     |  | \[h1\] Heading 1    |                           |  
|   \> ...          |  | \[@\] Mention User  |                           |  
| \> Marketing      |  | \[\[ Link Document |                           |  
| \> HR             |  | \[code\] Code block |                           |  
|                  |  \+-------------------+                           |  
| \[Private\]        |                                                   |  
| \[Settings\]       |                                                   |  
\+------------------+---------------------------------------------------+

**Visualization: The Smart Folder Suggestion Modal (NEW)**

\+-------------------------------------------------+  
|  Move "Engineering Onboarding Guide"            |  
\+-------------------------------------------------+  
|                                                 |  
|  SMART SUGGESTIONS                              |  
|  \[Space\] Engineering \> \[Folder\] Guides          |  
|  \[Space\] HR \> \[Folder\] Onboarding               |  
|                                                 |  
|  \--- OR BROWSE \---                              |  
|                                                 |  
|  \[Search locations...\]                          |  
|                                                 |  
|  \[Space\] Engineering                            |  
|  \[Space\] Marketing                              |  
|  \[Space\] HR                                     |  
|                                                 |  
|  \[Cancel\]               \[Move Here\]             |  
\+-------------------------------------------------+

### 

### **3.5 Epic 4: Granular Permissions System**

This is the core of our "permissions-first" architecture.

* **FR 4.1: Access Levels:** Permissions must be controlled at the Doc level and Space level.  
* **FR 4.2: Role-Based Access:** Admins/Doc-owners must be able to grant Read or Write access to:  
  * **Individual Users:** (e.g., david@company.com)  
  * **Teams:** (e.g., the "Engineering" team)  
  * **Guests:** (e.g., external-consultant@gmail.com \- single-space access only)  
* **FR 4.3: Privilege Logic:** The highest privilege wins (e.g., Read as a User \+ Write as part of a Team \= Write access).  
* **FR 4.4: Public Links:** Must support read-only public links for a single Document.

### **3.6 Epic 5: User & Team Management**

* **FR 5.1: Admin Panel:** Admins must have an "Admin Panel" to manage the organization.  
* **FR 5.2: User Management:** Admins can invite/deactivate Users.  
* **FR 5.3: Team Management:** Admins can create/manage Teams (e.g., "Engineering," "Marketing") and add/remove users from them.

### 

### **3.7 Epic 6: Mentions & Notifications**

This epic handles the system for notifying users.

* **FR 6.1: Notification System:** A new "Inbox" icon will appear in the main UI (see visualization 3.4). A badge will indicate unread notifications.  
* **FR 6.2: Mention Notifications:** When a user is mentioned (@User), they receive an in-app notification. When a team is mentioned (@Team), all members of that team receive an in-app notification.  
* **FR 6.3: "Mentions View":** Clicking the "Inbox" icon opens a view showing a list of all documents where the user has been mentioned, sorted by most recent.  
* **FR 6.4: Email Notifications (Optional):** Users can opt-in to receive email notifications for mentions.

### **3.8 Epic 7: Bi-Directional Linking**

This epic provides Obsidian-like context for documents.

* **FR 7.1: Backlinks View:** At the bottom of every document, a dedicated section will automatically display all "Backlinks" (documents that link *to* this document).  
* **FR 7.2: Outgoing Links View:** In the same section, a toggle or separate tab will show all "Outgoing Links" (all \[\[Doc Links\]\] that exist *within* the current document).  
* **FR 7.3: Graph View (Post-MVP):** A visual graph of how documents link together will be considered for V1.1, but is not in the MVP scope.

**Visualization: The Document Links Section (Bottom of Doc)**

\+---------------------------------------------------+  
|  ...end of the document content.                       |  
|                                                                                 |  
|  \<hr\>                                                                       |  
|                                                                                 |  
|  LINKS TO THIS DOCUMENT (BACKLINKS)      |  
|  \[doc\] Project Phoenix \- Launch Plan               |  
|        ...our strategy is based on the \[\[API...       |  
|                                                                                |  
|  \[doc\] Developer Onboarding Checklist          |  
|        ...new hires must read the \[\[API Guide\]\]   |  
\+---------------------------------------------------+

## **4\. Cross-Platform & Offline Sync Strategy (V1.0)**

WRight Now must be available wherever the user is, with full offline capabilities.

### **4.1 Platform: Web (V1.0)**

* **Technology:** React (or similar modern frontend framework).  
* **Priority:** This is the primary V1.0 application. It must be fully responsive.

### **4.2 Platform: Desktop (Windows, macOS, Linux) (V1.0)**

* **Technology:** Electron (or Tauri).  
* **Priority:** This is a "wrapper" for the web app, *not* a separate build.  
* **Added Features:**  
  * **Global Hotkey:** Register Cmd+K / Ctrl+K at the OS level, so the user can summon WRight Now's search *from any other application*.  
  * **Offline Access:** Must have full "Read" and "Write" (CRUD) capabilities while offline.  
  * **Offline Sync:** Offline changes must sync upon reconnection after re-validating permissions.  
  * Native OS notifications.

### 

### **4.3 Platform: Mobile (iOS & Android) (V1.0)**

* **Strategy:** **Read, Search, and Edit.**  
* **Technology:** React Native.  
* **Core Features:**  
  * **Tab 1: Search:** The app opens to a prominent RAG search bar.  
  * **Tab 2: Recents:** A list of recently viewed documents.  
  * **Tab 3: Inbox:** A native view of the user's mentions.  
  * Tab 4: Browse: A native-feeling view of the "Boring" Hierarchy.  
    Note: AI Folder Suggestions (FR 3.5) will be integrated into the save/move workflow.  
  * **Editing:** Users must have full "Read" and "Write" (CRUD) capabilities, including offline.  
  * **Offline Sync:** Offline changes must sync upon reconnection.

**Visualization: The Mobile App (Updated)**

\+-----------------------------------+  
| \[Search\] Find or ask anything...  |  
\+-----------------------------------+  
|                                   |  
| RECENTLY VIEWED                   |  
| \[doc\] Project Phoenix \- Launch... |  
| \[doc\] Q4 Marketing Budget         |  
| \[doc\] Engineering Onboarding...   |  
|                                   |  
|                                   |  
|                                   |  
|                                   |  
|-----------------------------------|  
| \[Search\] \[Recents\] \[Inbox\] \[Browse\]|  
\+-----------------------------------+

## 

## **5\. Non-Functional Requirements (NFRs)**

### **5.1 Security**

* **NFR 1.1: Zero-Trust:** All API endpoints and data queries must be protected by the PermissionsService. No data is accessible by default.  
* **NFR 1.2: Encryption:** Data must be encrypted at-rest (TDE in Postgres) and in-transit (SSL). Offline databases on client devices must also be encrypted.  
* **NFR 1.3: Data Isolation:** A user in Org A must *never* be able to access Org B's data. This will be enforced by a hard org\_id check on all DB queries.

### **5.2 Performance**

* **NFR 2.1: Permission Checks:** All permission lookups (hot path) must resolve in p99 \< 10ms (to be achieved via Redis caching).  
* **NFR 2.2: API Response:** All standard API endpoints must respond in p95 \< 200ms.  
* **NFR 2.3: UI Interaction:** The Cmd+K modal must open in \< 100ms.

### **5.3 Scalability**

* **NFR 3.1: Horizontal Scaling:** The backend (Nest.js) and AI service (FastAPI) must be stateless and horizontally scalable via container orchestration (Kubernetes).

### **5.4 Reliability**

* **NFR 4.1: Uptime:** The system will aim for 99.9% uptime.  
* **NFR 4.2: Sync Integrity:** Real-time sync must be robust and not lose user data during merge conflicts (handled by Yjs CRDTs).

### **5.5 Maintainability**

* **NFR 5.1: TDD:** All code must follow Test-Driven Development (TDD).  
* **NFR 5.2: CI/CD:** All new features must be preceded by failing tests and must pass a CI/CD pipeline.

## 

## **6\. Pricing & Tiers (GTM)**

This model supports both FOSS self-hosters and users of our managed cloud version.

* **Tier 1: Community (FOSS)**  
  * **Price:** $0 (Free)  
  * **Includes:** The full FOSS backend (WRight Now Core). Requires self-hosting. Community-based support.  
  * **Target:** Developers, hobbyists, and security-conscious teams who want to manage their own instance.  
* **Tier 2: Founder's LTD (Launch Only)**  
  * **Price:** $99 one-time payment.  
  * **Includes:** **Our hosted cloud version.** 1 Workspace, 5 users, 10GB storage.  
  * **Target:** Our first 1,000 "ambassadors" for the cloud product.  
* **Tier 3: Starter (MRR V1 \- Hosted)**  
  * **Price:** $49/month (flat rate).  
  * **Includes:** **Our hosted cloud version.** 1 Workspace, 10 users, 50GB storage.  
  * **Target:** The 10-50 person team.  
* **Tier 4: Growth (MRR V2 \- Hosted)**  
  * **Price:** $8/user/month (billed annually) or $10/user/month (billed monthly).  
  * **Includes:** **Our hosted cloud version.** Unlimited Workspaces, unlimited storage, advanced permissions.  
  * **Target:** The 50-500 person SMB.  
* **Tier 5: Enterprise (Self-Hosted Support)**  
  * **Price:** Custom (Annual Contract).  
  * **Includes:** Premium support for the self-hosted FOSS version, SAML-based SSO, advanced security audits, and deployment support.  
* **Target:** Large enterprises that must self-host for compliance but require professional support.

## 

## **7\. Future Roadmap (Post V1.0)**

* **V1.1:** Deeper Integrations (Slack, GitHub). Post link previews, /wrightnow search from Slack.  
* **V1.2:** "Ask Your Wiki" (ChatBot) \- A chat-based AI interface that uses the RAG index to hold a conversation about company knowledge.  
* **V1.3:** Public-facing documentation. A toggle to make a "Space" public with a custom domain (competing with GitBook).  
* **V1.4:** Graph View. A visual, interactive graph of all bi-directionally linked documents.

