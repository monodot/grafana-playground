#!/bin/sh

while true; do
    echo "Exception in thread \"main\" org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'embeddedServletContainerCustomizerBeanPostProcessor': BeanPostProcessor before instantiation of bean failed; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'org.springframework.security.config.annotation.method.configuration.GlobalMethodSecurityConfiguration': Injection of autowired dependencies failed; nested exception is org.springframework.beans.factory.BeanCreationException: Could not autowire method: public void org.springframework.security.config.annotation.method.configuration.GlobalMethodSecurityConfiguration.setAuthenticationConfiguration(org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration); nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration': Injection of autowired dependencies failed; nested exception is org.springframework.beans.factory.BeanCreationException: Could not autowire method: public void org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration.setGlobalAuthenticationConfigurers(java.util.List) throws java.lang.Exception; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'com.sample.Application$AuthenticationSecurity': Injection of autowired dependencies failed; nested exception is org.springframework.beans.factory.BeanCreationException: Could not autowire field: private com.sample.service.UserAccountService com.sample.Application$AuthenticationSecurity.userAccountService; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'userAccountService': Injection of autowired dependencies failed; nested exception is org.springframework.beans.factory.BeanCreationException: Could not autowire field: protected com.sample.model.RoleRepository com.sample.service.UserAccountService.roleRepository; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'roleRepository': Cannot create inner bean '(inner bean)#619587e5' of type [org.springframework.orm.jpa.SharedEntityManagerCreator] while setting bean property 'entityManager'; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name '(inner bean)#619587e5': Cannot resolve reference to bean 'entityManagerFactory' while setting constructor argument; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'entityManagerFactory' defined in class path resource [org/springframework/boot/autoconfigure/orm/jpa/HibernateJpaAutoConfiguration.class]: Invocation of init method failed; nested exception is javax.persistence.PersistenceException: [PersistenceUnit: default] Unable to build Hibernate SessionFactory"
    echo "	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:471)"
    echo "	at org.springframework.beans.factory.support.AbstractBeanFactory\$1.getObject(AbstractBeanFactory.java:302)"
    echo "	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:228)"
    echo "	at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:298)"
    echo "	at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:198)"
    echo "	at org.springframework.context.support.PostProcessorRegistrationDelegate.registerBeanPostProcessors(PostProcessorRegistrationDelegate.java:232)"
    echo "	at org.springframework.context.support.AbstractApplicationContext.registerBeanPostProcessors(AbstractApplicationContext.java:618)"
    echo "	at org.springframework.context.support.AbstractApplicationContext.__refresh(AbstractApplicationContext.java:467)"
    echo "	at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java)"
    echo "	at org.springframework.boot.context.embedded.EmbeddedWebApplicationContext.refresh(EmbeddedWebApplicationContext.java:120)"
    echo "	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:691)"
    echo "	at org.springframework.boot.SpringApplication.run(SpringApplication.java:320)"
    echo "	at org.springframework.boot.SpringApplication.run(SpringApplication.java:952)"
    echo "	at org.springframework.boot.SpringApplication.run(SpringApplication.java:941)"
    echo "	at com.sample.Application.main(Application.java:51)"

    sleep 10
done

