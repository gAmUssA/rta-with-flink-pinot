import os
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from pinotdb import connect
import time

def to_epoch_millis(dt):
    """Convert datetime to epoch milliseconds"""
    return int(dt.timestamp() * 1000)

class ProductAnalyticsDashboard:
    def __init__(self):
        pinot_host = os.getenv('PINOT_HOST', 'localhost')
        pinot_port = os.getenv('PINOT_PORT', '8099')
        self.conn = connect(host=pinot_host, port=pinot_port, path='/query/sql', scheme='http')
        st.set_page_config(
            page_title="Product Analytics",
            layout="wide",
            menu_items={
                'Get Help': 'https://github.com/gAmUssA/rta-with-flink-pinot',
                'Report a bug': "https://github.com/gAmUssA/rta-with-flink-pinot/issues",
                'About': "Real-time Analytics Dashboard using Apache Pinot"
            }
        )
        
    def run(self):
        st.title("Product Analytics Dashboard")
        
        # Sidebar configuration
        with st.sidebar:
            st.header("Dashboard Settings")
            
            # Auto-refresh settings
            st.subheader("Auto Refresh")
            refresh_interval = st.slider(
                "Refresh Interval (seconds)",
                min_value=5,
                max_value=300,
                value=30,
                step=5
            )
            auto_refresh = st.toggle("Enable Auto Refresh", value=True)
            
            if auto_refresh:
                st.info(f"Dashboard will refresh every {refresh_interval} seconds")
            
            # Time range settings
            st.subheader("Time Range")
            time_range = st.selectbox(
                "Preset Time Ranges",
                ["Last 24 Hours", "Last 7 Days", "Last 30 Days", "Custom"]
            )
            
            if time_range == "Last 24 Hours":
                start_date = datetime.now() - timedelta(days=1)
                end_date = datetime.now()
            elif time_range == "Last 7 Days":
                start_date = datetime.now() - timedelta(days=7)
                end_date = datetime.now()
            elif time_range == "Last 30 Days":
                start_date = datetime.now() - timedelta(days=30)
                end_date = datetime.now()
            else:  # Custom
                col1, col2 = st.columns(2)
                with col1:
                    start_date = st.date_input(
                        "Start Date",
                        datetime.now() - timedelta(days=7)
                    )
                with col2:
                    end_date = st.date_input(
                        "End Date",
                        datetime.now()
                    )
            
        # Convert dates to datetime with time
        if isinstance(start_date, datetime):
            start_dt = start_date
        else:
            start_dt = datetime.combine(start_date, datetime.min.time())
            
        if isinstance(end_date, datetime):
            end_dt = end_date
        else:
            end_dt = datetime.combine(end_date, datetime.max.time())
        
        # Display current time range
        st.caption(f"Showing data from {start_dt.strftime('%Y-%m-%d %H:%M')} to {end_dt.strftime('%Y-%m-%d %H:%M')}")
            
        # Main metrics
        self.show_key_metrics(start_dt, end_dt)
        
        # Tabs for different views
        tab1, tab2 = st.tabs([
            "Product Performance", "Revenue Analysis"
        ])
        
        with tab1:
            self.show_product_performance(start_dt, end_dt)
        
        with tab2:
            self.show_revenue_analysis(start_dt, end_dt)
            
        # Auto-refresh logic
        if auto_refresh:
            time.sleep(refresh_interval)  # Wait for the specified interval before refreshing
            st.rerun()

    def show_key_metrics(self, start_dt, end_dt):
        query = """
        SELECT 
            SUM(view_count) as total_views,
            SUM(cart_adds) as total_cart_adds,
            SUM(purchases) as total_purchases,
            SUM(revenue) as total_revenue
        FROM product_analytics
        WHERE update_time BETWEEN %(start_ts)s AND %(end_ts)s
        """
        
        df = pd.read_sql(query, self.conn, params={
            'start_ts': to_epoch_millis(start_dt),
            'end_ts': to_epoch_millis(end_dt)
        })
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Total Views", f"{df['total_views'].iloc[0]:,.0f}")
        with col2:
            st.metric("Cart Adds", f"{df['total_cart_adds'].iloc[0]:,.0f}")
        with col3:
            st.metric("Purchases", f"{df['total_purchases'].iloc[0]:,.0f}")
        with col4:
            st.metric("Revenue", f"${df['total_revenue'].iloc[0]:,.2f}")

    def show_product_performance(self, start_dt, end_dt):
        st.subheader("Product Performance")
        
        # Product performance analysis
        product_query = """
        SELECT 
            product_name,
            product_category,
            SUM(view_count) as views,
            SUM(cart_adds) as cart_adds,
            SUM(purchases) as purchases,
            SUM(revenue) as revenue
        FROM product_analytics
        WHERE update_time BETWEEN %(start_ts)s AND %(end_ts)s
        GROUP BY product_name, product_category
        ORDER BY revenue DESC
        """
        
        df = pd.read_sql(product_query, self.conn, params={
            'start_ts': to_epoch_millis(start_dt),
            'end_ts': to_epoch_millis(end_dt)
        })
        
        if not df.empty:
            # Calculate conversion rates
            df['view_to_cart'] = (df['cart_adds'] / df['views'] * 100).round(1)
            df['cart_to_purchase'] = (df['purchases'] / df['cart_adds'] * 100).round(1)
            
            # Product performance table
            st.dataframe(
                df.style.format({
                    'revenue': '${:,.2f}',
                    'view_to_cart': '{:.1f}%',
                    'cart_to_purchase': '{:.1f}%'
                }),
                use_container_width=True
            )
            
            # Top products by revenue
            fig = px.bar(
                df.head(10),
                x='product_name',
                y='revenue',
                color='product_category',
                title="Top 10 Products by Revenue"
            )
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No data available for the selected date range")

    def show_revenue_analysis(self, start_dt, end_dt):
        st.subheader("Revenue Analysis")
        
        # Create placeholder for the trend chart
        trend_chart_placeholder = st.empty()
        
        # Create placeholder for the category distribution
        category_chart_placeholder = st.empty()
        category_table_placeholder = st.empty()
        
        # Revenue trend over time (1-minute buckets for more granular data)
        trend_query = """
        SELECT 
            FLOOR(update_time/60000) * 60000 as time_bucket,
            SUM(revenue) as revenue,
            COUNT(*) as record_count
        FROM product_analytics
        WHERE update_time BETWEEN %(start_ts)s AND %(end_ts)s
        GROUP BY FLOOR(update_time/60000) * 60000
        ORDER BY time_bucket ASC
        """
        
        trend_df = pd.read_sql(trend_query, self.conn, params={
            'start_ts': to_epoch_millis(start_dt),
            'end_ts': to_epoch_millis(end_dt)
        })
        
        if not trend_df.empty:
            # Convert time_bucket from epoch millis to datetime
            trend_df['time_bucket'] = pd.to_datetime(trend_df['time_bucket'], unit='ms')
            
            # Create revenue trend line chart
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=trend_df['time_bucket'],
                y=trend_df['revenue'],
                mode='lines+markers',
                name='Revenue',
                line=dict(color='#2E86C1', width=2),
                marker=dict(size=4),
                hovertemplate='Time: %{x}<br>Revenue: $%{y:,.2f}<br>Records: %{text}<extra></extra>',
                text=trend_df['record_count']
            ))
            
            fig.update_layout(
                title=f"Revenue Trend Over Time (Total: ${trend_df['revenue'].sum():,.2f})",
                xaxis_title="Time",
                yaxis_title="Revenue ($)",
                hovermode='x unified',
                yaxis_tickprefix='$',
                yaxis_tickformat=',.2f',
                xaxis=dict(
                    tickformat='%Y-%m-%d %H:%M:%S',
                    tickangle=45
                )
            )
            
            # Update the trend chart placeholder
            trend_chart_placeholder.plotly_chart(fig, use_container_width=True)
        
        # Revenue by category
        category_query = """
        SELECT 
            product_category,
            SUM(revenue) as revenue,
            SUM(purchases) as purchases
        FROM product_analytics
        WHERE update_time BETWEEN %(start_ts)s AND %(end_ts)s
        GROUP BY product_category
        ORDER BY revenue DESC
        """
        
        df = pd.read_sql(category_query, self.conn, params={
            'start_ts': to_epoch_millis(start_dt),
            'end_ts': to_epoch_millis(end_dt)
        })
        
        if not df.empty:
            # Revenue by category pie chart
            fig = px.pie(
                df,
                values='revenue',
                names='product_category',
                title=f"Revenue Distribution by Category (Total: ${df['revenue'].sum():,.2f})"
            )
            fig.update_traces(
                textposition='inside',
                textinfo='percent+label',
                hovertemplate='Category: %{label}<br>Revenue: $%{value:,.2f}<br>Percentage: %{percent}<extra></extra>'
            )
            
            # Update the category chart placeholder
            category_chart_placeholder.plotly_chart(fig, use_container_width=True)
            
            # Update the category table placeholder
            category_table_placeholder.dataframe(
                df.style.format({
                    'revenue': '${:,.2f}',
                    'purchases': '{:,.0f}'
                }),
                use_container_width=True
            )
        else:
            trend_chart_placeholder.warning("No data available for the selected date range")
            category_chart_placeholder.warning("No data available for the selected date range")

if __name__ == "__main__":
    dashboard = ProductAnalyticsDashboard()
    dashboard.run()