import json
import logging
import os
import random
import time
from typing import Dict, List
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel

from faker import Faker
from kafka import KafkaProducer

from analytics_generator.models import (
    AddToCartEvent,
    PageViewEvent,
    ProductViewEvent,
    PurchaseEvent,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
fake = Faker()

class EventGenerator:
    """Generates and sends analytics events to Kafka."""

    def __init__(self, bootstrap_servers: str, topic: str):
        """Initialize the event generator.

        Args:
            bootstrap_servers: Kafka bootstrap servers
            topic: Kafka topic to send events to
        """
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda x: json.dumps(x, default=lambda x: x.isoformat() if isinstance(x, datetime) else str(x)).encode("utf-8"),
        )
        self.products_by_category = self._generate_product_catalog()

    def _generate_product_catalog(self) -> Dict[str, List[Dict]]:
        """Generate a catalog of products by category."""
        categories = ["Electronics", "Clothing", "Books", "Home & Garden", "Sports"]
        catalog = {}
        for category in categories:
            catalog[category] = [
                {
                    "id": fake.uuid4(),
                    "name": fake.catch_phrase(),
                    "price": round(random.uniform(10, 1000), 2),
                }
                for _ in range(20)
            ]
        return catalog

    def _generate_user_data(self) -> Dict[str, str]:
        """Generate random user data."""
        return {
            "user_id": fake.uuid4(),
            "session_id": fake.uuid4(),
            "device_type": random.choice(["desktop", "mobile", "tablet"]),
            "os": random.choice(["Windows", "MacOS", "iOS", "Android", "Linux"]),
            "browser": random.choice(["Chrome", "Firefox", "Safari", "Edge"]),
            "location": fake.city(),
        }

    def _generate_page_view(self) -> Dict:
        """Generate a page view event."""
        user_data = self._generate_user_data()
        event = PageViewEvent(
            **user_data,
            page_url=fake.url(),
            referrer_url=fake.url() if random.random() > 0.3 else None,
            time_spent=round(random.uniform(5, 300), 2),
        )
        return event.model_dump()

    def _generate_product_view(self) -> Dict:
        """Generate a product view event."""
        user_data = self._generate_user_data()
        category = random.choice(list(self.products_by_category.keys()))
        product = random.choice(self.products_by_category[category])
        event = ProductViewEvent(
            **user_data,
            product_id=product["id"],
            product_name=product["name"],
            product_category=category,
            price=product["price"],
        )
        return event.model_dump()

    def _generate_add_to_cart(self) -> Dict:
        """Generate an add to cart event."""
        user_data = self._generate_user_data()
        category = random.choice(list(self.products_by_category.keys()))
        product = random.choice(self.products_by_category[category])
        event = AddToCartEvent(
            **user_data,
            product_id=product["id"],
            product_name=product["name"],
            product_category=category,
            price=product["price"],
            quantity=random.randint(1, 5),
        )
        return event.model_dump()

    def _generate_purchase(self) -> Dict:
        """Generate a purchase event."""
        user_data = self._generate_user_data()
        category = random.choice(list(self.products_by_category.keys()))
        product = random.choice(self.products_by_category[category])
        quantity = random.randint(1, 5)
        event = PurchaseEvent(
            **user_data,
            order_id=fake.uuid4(),
            product_id=product["id"],
            product_name=product["name"],
            product_category=category,
            price=product["price"],
            quantity=quantity,
            total_amount=round(product["price"] * quantity, 2),
        )
        return event.model_dump()

    def generate_event(self) -> Dict:
        """Generate a random event."""
        event_types = [
            (self._generate_page_view, 0.4),
            (self._generate_product_view, 0.3),
            (self._generate_add_to_cart, 0.2),
            (self._generate_purchase, 0.1),
        ]
        generator_func = random.choices(
            [et[0] for et in event_types],
            weights=[et[1] for et in event_types],
        )[0]
        return generator_func()

    def send_event(self, event: Dict):
        """Send an event to Kafka."""
        try:
            self.producer.send(self.topic, event)
            logger.debug(f"Sent event: {event}")
        except Exception as e:
            logger.error(f"Error sending event: {e}")

    def run(self, events_per_second: int = 1):
        """Run the event generator."""
        logger.info(
            f"Starting event generator with {events_per_second} events per second"
        )
        while True:
            event = self.generate_event()
            self.send_event(event)
            time.sleep(1 / events_per_second)


if __name__ == "__main__":
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    topic = os.getenv("KAFKA_TOPIC", "analytics_events")
    events_per_second = int(os.getenv("EVENTS_PER_SECOND", "1"))

    generator = EventGenerator(bootstrap_servers=bootstrap_servers, topic=topic)
    generator.run(events_per_second=events_per_second)
