package com.example.camel;

import com.zaxxer.hikari.HikariDataSource;
import org.apache.activemq.artemis.jms.client.ActiveMQConnectionFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import jakarta.jms.ConnectionFactory;
import javax.sql.DataSource;

@Configuration
public class CamelConfiguration {

    @Value("${db.url}")
    private String dbUrl;

    @Value("${db.user}")
    private String dbUser;

    @Value("${db.password}")
    private String dbPassword;

    @Value("${activemq.broker.url}")
    private String brokerUrl;

    @Value("${activemq.user}")
    private String activemqUser;

    @Value("${activemq.password}")
    private String activemqPassword;

    @Bean(name = "dataSource")
    public DataSource dataSource() {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setJdbcUrl(dbUrl);
        dataSource.setUsername(dbUser);
        dataSource.setPassword(dbPassword);
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setMaximumPoolSize(10);
        dataSource.setMinimumIdle(2);
        return dataSource;
    }

    @Bean
    public ConnectionFactory jmsConnectionFactory() {
        ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(brokerUrl);
        connectionFactory.setUser(activemqUser);
        connectionFactory.setPassword(activemqPassword);
        return connectionFactory;
    }

    @Bean
    public org.apache.camel.component.jms.JmsComponent jms(ConnectionFactory jmsConnectionFactory) {
        org.apache.camel.component.jms.JmsComponent component = new org.apache.camel.component.jms.JmsComponent();
        component.setConnectionFactory(jmsConnectionFactory);
        return component;
    }
}
