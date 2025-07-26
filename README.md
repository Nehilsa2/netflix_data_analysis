
# 🎬 Netflix – Advanced SQL Analytics  

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg" width="300" alt="Netflix Logo">
</p>

<p align="center">
  <img src="https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif" alt="Netflix Animation" width="600">
</p>

> **A powerful SQL analytics project built on Netflix titles dataset.**  
> Explore advanced queries, patterns, and insights into the global content library using PostgreSQL.

---

## 🚀 **Features**
- **Advanced SQL queries** – Window functions, CTEs, ranking, and more.  
- **Genre & Country Analysis** – Explore content distribution by country and genre.  
- **Trends Over Time** – Year-over-year and monthly content insights.  
- **Actor & Director Insights** – Most frequent collaborations and top contributors.  
- **Percentiles & Ratios** – Statistical insights like 90th percentile movie duration.  
- **Materialized Views** – Pre-computed aggregations for faster analytics.

---

## 🗂 **Dataset**
The dataset contains information about movies and TV shows on Netflix:  

<p align="center">
  <a href="https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download">
    <img src="https://img.shields.io/badge/Download%20Dataset-FF0000?style=for-the-badge&logo=kaggle&logoColor=white" alt="Download Dataset">
  </a>
</p>

**Columns:**  
- `show_id` – Unique identifier  
- `type` – Movie / TV Show  
- `title` – Name of the content  
- `director` – Director(s) of the title  
- `cast` – Leading actors  
- `country` – Country of production  
- `date_added` – Date added to Netflix  
- `release_year` – Release year of the title  
- `rating` – Age rating (e.g., PG-13, TV-MA)  
- `duration` – Duration (e.g., `90 min` or `2 Seasons`)  
- `listed_in` – Genres  
- `description` – Brief overview of the content  

---

## ⚡ **Quick Start**
```bash
# Clone this repository
git clone https://github.com/your-username/netflix-sql-analytics.git

# Open in your SQL client (e.g., pgAdmin or psql)
\i netflix_advanced_queries.sql
```

---

## 📊 **Sample Advanced Queries**

### 1️⃣ Top 10 Genres by Content
```sql
WITH g AS (
  SELECT TRIM(unnest(string_to_array(listed_in, ','))) AS genre
  FROM netflix
)
SELECT genre, COUNT(*) AS cnt
FROM g
GROUP BY genre
ORDER BY cnt DESC
LIMIT 10;
```

### 2️⃣ Year-over-Year Growth
```sql
WITH y AS (
  SELECT release_year, COUNT(*) AS cnt
  FROM netflix
  GROUP BY release_year
)
SELECT release_year,
       cnt,
       cnt - LAG(cnt) OVER (ORDER BY release_year) AS yoy_growth
FROM y;
```

---

## 🏆 **Key Insights**
- **India ranks among the top countries** in Netflix content releases.
- **Crime TV Shows** and **International TV Shows** dominate globally.
- The **longest movies** often come from historical dramas or action films.

---


## 🛠 **Tech Stack**
- **Database:** PostgreSQL  
- **Queries:** Advanced SQL (Window Functions, CTEs, Grouping Sets)  
- **Visualization:** Power BI / Tableau (optional)  

---

## 📌 **Future Enhancements**
- [ ] Add **stored procedures** for automated insights.  
- [ ] Create **REST API endpoints** to expose query results.  
- [ ] Build a **React dashboard** for visualization.  

---
<p align="center">
  <img src="https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExZTQ2Y2xodmd6ZWhrYndmM3VxZjQ3Nzd1MTQ4Mm9yOWYzOGJwYjFnbyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/AXdGgQfbeng2x7cX8i/giphy.gif" alt="Thank You Animation" width="400">
</p>


---
