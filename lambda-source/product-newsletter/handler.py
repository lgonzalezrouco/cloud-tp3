import os
import json
import psycopg2
import boto3

sns_client = boto3.client('sns')

def lambda_handler(event, context):
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password
        )
        cursor = conn.cursor()
        
        query = """
            SELECT id, name, description, category, price, image_url
            FROM products
            WHERE deleted = FALSE AND paused = FALSE
            ORDER BY id DESC
            LIMIT 10
        """
        
        cursor.execute(query)
        products = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        if not products:
            return {'statusCode': 200, 'body': json.dumps('No hay productos disponibles')}
        
        email_body = "🛍️ Últimos productos disponibles en MatchMarket:\n\n"
        email_body += "=" * 60 + "\n\n"
        
        for product in products:
            pid, name, desc, category, price, image = product
            email_body += f"📦 {name}\n"
            email_body += f"   ID: {pid}\n"
            email_body += f"   Categoría: {category}\n"
            email_body += f"   Precio: ${price:.2f}\n"
            if desc:
                email_body += f"   Descripción: {desc[:150]}...\n"
            if image:
                email_body += f"   Imagen: {image}\n"
            email_body += "\n" + "-" * 60 + "\n\n"
        
        email_body += "\n¡No te pierdas estas ofertas!\n"
        
        response = sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject='📧 Newsletter: Nuevos Productos en MatchMarket',
            Message=email_body
        )
        
        print(f"Email enviado. MessageId: {response['MessageId']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Newsletter enviado con {len(products)} productos',
                'messageId': response['MessageId']
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}